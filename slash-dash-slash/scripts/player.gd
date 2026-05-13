extends CharacterBody2D

## Player.
##
## Listens to InputSystem.dash_requested and aim_changed; rotates the sprite to
## face current aim while idle; runs a curve-driven committed dash on commit.
## Sets InputSystem.dash_in_progress true during the dash so the input buffer
## flushes correctly on completion (yielding zero-frame chained dashes).
##
## Distance and duration are derived from `tuning` plus per-key modifier
## registries that other systems install into. Modifiers are snapshotted at
## dash start; mid-dash mutations don't affect the in-flight motion.
##
## Wall collision is intentionally *not* handled here. `move_and_collide` is
## used for stepping so a future `wall_collision_dash` spec can plug in by
## reading the returned `KinematicCollision2D`.

# ===== Signals =====

signal dash_started(direction: Vector2)
signal dash_ended(traveled: Vector2)

## Emitted when an in-flight dash is interrupted by a wall. Fires before
## `dash_ended`, with the contact point and surface normal from the
## `KinematicCollision2D`.
signal wall_hit(position: Vector2, normal: Vector2)

## Sword fired this dash. Hit-detection consumes this; gem procs piggyback later.
signal weapon_fired(direction: Vector2)

## Sword transitioned reloading -> loaded (cooldown done AND stamina >= 1).
signal weapon_loaded

## Sword transitioned loaded -> reloading.
signal weapon_unloaded

## Stamina changed (drain or regen). UI listens here.
signal stamina_changed(current: int, max: int)

## A slash dash made contact with an enemy. Per-dash, per-enemy (no double-tap).
## `final_damage` is the post-armor value (what actually came off the enemy's
## health). `is_back_hit` comes from the enemy's own side calc — single source
## of truth, no duplication. Future systems (gem procs, audio, juice) listen here.
signal hit_landed(target: Node, final_damage: int, position: Vector2, dash_direction: Vector2, is_back_hit: bool)

## Player took damage. Future UI / juice listens here.
signal damaged(amount: int)

## Player health reached 0. Emitted once.
signal died

# ===== Tunables =====

const TUNING_PATH := "res://resources/dash_tuning.tres"
const HIT_TUNING_PATH := "res://resources/hit_tuning.tres"
const DEFAULT_SWORD_PATH := "res://resources/equipment/swords/letter_opener.tres"
const DEFAULT_AMULET_PATH := "res://resources/equipment/amulets/id_lanyard.tres"

# Floors clamping pathological modifier stacks so dashes always commit.
const MIN_DISTANCE: float = 1.0
const MIN_DURATION: float = 0.01

@export var tuning: DashTuning
@export var hit_tuning: HitTuning

## Equipment chosen at run start (per GDD: sword + amulet only).
## Future `equipment-selection-ui` will let the player pick at run start.
@export var equipped_sword: SwordStats
@export var equipped_amulet: AmuletStats

# ===== Public state =====

## Most recent aim direction received from the input system.
var current_aim: Vector2 = Vector2.RIGHT

## Whether a dash is currently in flight.
var is_dashing: bool = false

## True when the next dash will fire the sword (cooldown elapsed AND stamina >= 1).
var is_weapon_loaded: bool = false

## Current stamina, in [0, equipped_sword.max_stamina].
var stamina: int = 0

## Current health, initialized from `equipped_amulet.max_health` in `_ready`.
var health: int = 0

## Set true the moment health reaches 0; guards against further damage and
## ignores subsequent dash inputs.
var _is_dead: bool = false

# Held reference so a fresh damage flash can interrupt the prior tween cleanly.
var _damage_flash_tween: Tween = null

# ===== Internal weapon state =====

var _cooldown_remaining: float = 0.0
var _regen_accumulator: float = 0.0

# ===== Internal hit-detection state =====

# Set of targets already hit during the current dash; reset on weapon_fired.
var _hit_this_dash: Dictionary = {}

# ===== Internal dash state =====

var _dash_direction: Vector2 = Vector2.RIGHT
var _dash_elapsed: float = 0.0
var _dash_duration_snapshot: float = 0.12
var _dash_distance_snapshot: float = 80.0
var _dash_start_position: Vector2 = Vector2.ZERO

# Baked cumulative integral of `speed_curve` over [0,1], plus its total.
# Sampled per-frame to compute "where the dash should be at this normalized t".
var _curve_baked: PackedFloat32Array = PackedFloat32Array()
var _curve_total_integral: float = 1.0

# ===== Modifier registries =====
# Each entry: { "additive": float, "multiplicative": float }
# Stat formula: effective = (base + Σadditive) * Πmultiplicative, clamped to MIN.

var _distance_mods: Dictionary = {}
var _duration_mods: Dictionary = {}

# ===== Trail =====

@onready var trail: Line2D = $Trail
@onready var body: Polygon2D = $Body
@onready var hit_area: Area2D = $HitArea
@onready var hit_area_shape: CollisionShape2D = $HitArea/HitAreaShape

# Held reference so a new dash can kill an in-flight fade. Without this, the
# fade tween would overwrite the new dash's freshly-reset alpha and clear its
# trail points mid-dash.
var _trail_fade_tween: Tween = null

# ===== Lifecycle =====

func _ready() -> void:
	add_to_group("player")
	_is_dead = false

	# Equipment load. Priority: RunState (selection scene) > scene-level export
	# > default path > class default. Selection always wins so the run-start
	# pick is honored even when player.tscn carries a debug export.
	if RunState.chosen_sword != null:
		equipped_sword = RunState.chosen_sword
	if equipped_sword == null:
		equipped_sword = load(DEFAULT_SWORD_PATH) as SwordStats
	if equipped_sword == null:
		push_error("Player: failed to load default SwordStats at %s; using class defaults." % DEFAULT_SWORD_PATH)
		equipped_sword = SwordStats.new()

	if RunState.chosen_amulet != null:
		equipped_amulet = RunState.chosen_amulet
	if equipped_amulet == null:
		equipped_amulet = load(DEFAULT_AMULET_PATH) as AmuletStats
	if equipped_amulet == null:
		push_error("Player: failed to load default AmuletStats at %s; using class defaults." % DEFAULT_AMULET_PATH)
		equipped_amulet = AmuletStats.new()
	health = equipped_amulet.max_health

	if tuning == null:
		tuning = load(TUNING_PATH) as DashTuning
		if tuning == null:
			push_error("Player: failed to load DashTuning at %s; using defaults." % TUNING_PATH)
			tuning = DashTuning.new()

	# Trail draws in world space — points stay where they were dropped even as
	# the player moves on through them.
	trail.top_level = true
	trail.global_position = Vector2.ZERO
	trail.global_rotation = 0.0
	trail.clear_points()
	trail.default_color = tuning.trail_color
	trail.modulate.a = 1.0

	InputSystem.dash_requested.connect(_on_dash_requested)
	InputSystem.aim_changed.connect(_on_aim_changed)
	# Defensive: never inherit a stuck dash flag from a previous run.
	InputSystem.dash_in_progress = false

	# Weapon init — sourced from the equipped sword.
	stamina = equipped_sword.max_stamina
	_cooldown_remaining = 0.0
	_regen_accumulator = 0.0
	is_weapon_loaded = true
	_apply_loaded_modulate(true)
	# Defer initial signal emit until after children (e.g., StaminaPips) have
	# finished their own _ready and connected. Children's _ready runs first,
	# so by the time we get here they're listening; deferring keeps things
	# strict-ordered if anyone connects via call_deferred themselves.
	call_deferred("emit_signal", "stamina_changed", stamina, equipped_sword.max_stamina)
	call_deferred("emit_signal", "weapon_loaded")

	# Hit-detection init.
	if hit_tuning == null:
		hit_tuning = load(HIT_TUNING_PATH) as HitTuning
		if hit_tuning == null:
			push_error("Player: failed to load HitTuning at %s; using defaults." % HIT_TUNING_PATH)
			hit_tuning = HitTuning.new()
	_apply_hit_radius()
	hit_area.monitoring = false
	hit_area.area_entered.connect(_on_hit_area_area_entered)
	weapon_fired.connect(_on_weapon_fired_for_hit)
	dash_ended.connect(_on_dash_ended_for_hit)

	# Audio: hand ourselves to the autoload so it can subscribe to all our
	# combat signals without us knowing what it plays.
	Audio.bind_to_player(self)

func _physics_process(delta: float) -> void:
	# Push player position so InputSystem can compute mouse-relative aim.
	InputSystem.player_world_position = global_position

	_tick_weapon(delta)

	if is_dashing:
		_advance_dash(delta)
	else:
		_update_idle_rotation()

# ===== Input handlers =====

func _on_aim_changed(direction: Vector2) -> void:
	current_aim = direction

func _on_dash_requested(direction: Vector2) -> void:
	# We only start a dash when idle. The input system buffers commits that
	# arrive mid-dash and re-emits them on dash_in_progress -> false.
	if _is_dead:
		return
	if is_dashing:
		return
	_start_dash(direction)

# ===== Dash lifecycle =====

func _start_dash(direction: Vector2) -> void:
	# Fire the sword at dash commit if loaded. Whether the dash actually contacts
	# an enemy is hit-detection's job; here we just consume cooldown + stamina.
	# Capture before _fire_weapon flips is_weapon_loaded so the trail can pick
	# the right color/width.
	var was_slash: bool = is_weapon_loaded
	if was_slash:
		_fire_weapon(direction.normalized() if direction.length() > 0.0 else current_aim)

	is_dashing = true
	_dash_direction = direction.normalized() if direction.length() > 0.0 else current_aim
	_dash_elapsed = 0.0
	_dash_distance_snapshot = _compute_effective(equipped_amulet.dash_distance, _distance_mods, MIN_DISTANCE)
	_dash_duration_snapshot = _compute_effective(tuning.base_dash_duration, _duration_mods, MIN_DURATION)
	_dash_start_position = global_position
	_bake_speed_curve()
	rotation = _dash_direction.angle()

	# Kill any in-flight fade tween from the previous dash so it can't stomp
	# on this dash's alpha or clear our points mid-flight.
	if _trail_fade_tween != null and _trail_fade_tween.is_valid():
		_trail_fade_tween.kill()
	_trail_fade_tween = null

	# Per-dash trail style: slashes get a wider blood-red line; repositions get
	# the narrower phosphor-green line.
	if was_slash:
		trail.default_color = tuning.slash_trail_color
		trail.width = tuning.slash_trail_width
	else:
		trail.default_color = tuning.trail_color
		trail.width = tuning.trail_width

	# Reset trail visuals and seed the first point at the dash origin.
	trail.modulate.a = 1.0
	trail.clear_points()
	trail.add_point(global_position)

	InputSystem.dash_in_progress = true
	dash_started.emit(_dash_direction)

func _advance_dash(delta: float) -> void:
	_dash_elapsed += delta
	var t: float = clampf(_dash_elapsed / _dash_duration_snapshot, 0.0, 1.0)
	var integral: float = _sample_baked_integral(t)
	var fraction: float = integral / _curve_total_integral if _curve_total_integral > 0.0 else t
	var target_position: Vector2 = _dash_start_position + _dash_direction * _dash_distance_snapshot * fraction
	var step: Vector2 = target_position - global_position
	var collision: KinematicCollision2D = move_and_collide(step)

	# Append trail point post-move so the wall position becomes the trail's tail.
	_append_trail_point(global_position)

	if collision != null:
		wall_hit.emit(collision.get_position(), collision.get_normal())
		_end_dash()
		return

	if t >= 1.0:
		_end_dash()

func _end_dash() -> void:
	var traveled: Vector2 = global_position - _dash_start_position
	is_dashing = false
	# Flushing the input buffer: setting dash_in_progress to false in the
	# InputSystem's setter re-emits any queued dash_requested *synchronously*,
	# which can re-enter `_start_dash` and flip `is_dashing` back to true
	# before this function returns. Check for that below before scheduling
	# the fade — we don't want to fade a dash that just started.
	InputSystem.dash_in_progress = false
	dash_ended.emit(traveled)

	# If a chained dash kicked off via the buffer flush, leave its trail alone.
	if is_dashing:
		return

	# Fade the trail out smoothly. Cleared after fade completes so a fresh
	# dash starts with no leftover ghost points.
	_trail_fade_tween = create_tween()
	_trail_fade_tween.tween_property(trail, "modulate:a", 0.0, tuning.trail_fade_duration)
	_trail_fade_tween.tween_callback(trail.clear_points)

# ===== Weapon =====

func _fire_weapon(dir: Vector2) -> void:
	stamina = maxi(0, stamina - 1)
	_cooldown_remaining = equipped_sword.cooldown_duration
	_regen_accumulator = 0.0
	is_weapon_loaded = false
	_apply_loaded_modulate(false)
	weapon_fired.emit(dir)
	weapon_unloaded.emit()
	stamina_changed.emit(stamina, equipped_sword.max_stamina)

func _tick_weapon(delta: float) -> void:
	# Cooldown countdown.
	if _cooldown_remaining > 0.0:
		_cooldown_remaining = maxf(0.0, _cooldown_remaining - delta)

	# Stamina regen — continuous, runs even mid-cooldown.
	if stamina < equipped_sword.max_stamina:
		_regen_accumulator += delta
		while _regen_accumulator >= equipped_sword.stamina_regen_interval and stamina < equipped_sword.max_stamina:
			_regen_accumulator -= equipped_sword.stamina_regen_interval
			stamina += 1
			stamina_changed.emit(stamina, equipped_sword.max_stamina)
		if stamina >= equipped_sword.max_stamina:
			_regen_accumulator = 0.0

	# Transition reloading -> loaded the moment both gates clear.
	if not is_weapon_loaded and _cooldown_remaining <= 0.0 and stamina >= 1:
		is_weapon_loaded = true
		_apply_loaded_modulate(true)
		weapon_loaded.emit()

func _apply_loaded_modulate(is_loaded: bool) -> void:
	if body == null:
		return
	body.modulate = equipped_sword.loaded_tint_color if is_loaded else Color(1, 1, 1, 1)

# ===== Damage =====

## Called by enemy AI when an attack lands. No-ops once dead.
func take_damage(amount: int) -> void:
	if _is_dead or amount <= 0:
		return
	health = maxi(0, health - amount)
	damaged.emit(amount)
	_flash_damage()
	if health <= 0:
		_on_player_died()

func _flash_damage() -> void:
	if body == null:
		return
	if _damage_flash_tween != null and _damage_flash_tween.is_valid():
		_damage_flash_tween.kill()
	body.modulate = Color(2.0, 1.5, 1.5, 1.0)  # red overbright
	_damage_flash_tween = create_tween()
	_damage_flash_tween.tween_property(body, "modulate", Color(1, 1, 1, 1), 0.2)
	# After the flash, re-apply the loaded/unloaded modulate so the weapon
	# state visual isn't stuck on plain white.
	_damage_flash_tween.tween_callback(func() -> void: _apply_loaded_modulate(is_weapon_loaded))

func _on_player_died() -> void:
	_is_dead = true
	print("[Player] died")
	died.emit()
	# Freeze: stop running our process callbacks and clear the input buffer
	# state so a queued dash doesn't fire post-death.
	set_process(false)
	set_physics_process(false)
	InputSystem.dash_in_progress = false

# ===== Hit detection =====

func _apply_hit_radius() -> void:
	# Read body radius from the existing CollisionShape2D so the player scene
	# stays the source of truth for body size.
	var body_radius: float = 6.0
	var body_shape := $CollisionShape2D as CollisionShape2D
	if body_shape != null and body_shape.shape is CircleShape2D:
		body_radius = (body_shape.shape as CircleShape2D).radius
	if hit_area_shape.shape is CircleShape2D:
		(hit_area_shape.shape as CircleShape2D).radius = body_radius + hit_tuning.hit_radius_offset

func _on_weapon_fired_for_hit(_direction: Vector2) -> void:
	_hit_this_dash.clear()
	hit_area.monitoring = true
	# Catch enemies already overlapping the HitArea (Godot's area_entered only
	# fires for transitions). Defer to next physics frame so monitoring takes
	# effect first.
	_check_initial_overlaps_async()

func _on_dash_ended_for_hit(_traveled: Vector2) -> void:
	hit_area.monitoring = false

func _on_hit_area_area_entered(area: Area2D) -> void:
	_try_hit(area)

func _check_initial_overlaps_async() -> void:
	await get_tree().physics_frame
	if not hit_area.monitoring:
		return  # dash already ended (e.g., zero-distance wall hit)
	for area in hit_area.get_overlapping_areas():
		_try_hit(area)

func _try_hit(target: Node) -> void:
	# Guards in order: still dashing (HitArea may flicker on the boundary),
	# valid node, walks-up to the enemy root (Hurtbox child of CharacterBody2D),
	# registered as an enemy, not already hit this dash.
	if not is_dashing:
		return
	if target == null or not is_instance_valid(target):
		return

	# Real enemies use a Hurtbox Area2D as a child of the enemy root; walk up.
	var enemy_root: Node = target.get_parent()
	if enemy_root == null or not enemy_root.is_in_group("enemy"):
		return
	if _hit_this_dash.has(enemy_root):
		return
	_hit_this_dash[enemy_root] = true

	# Snapshot position before take_dash_hit — the enemy may queue_free itself
	# during the call when health drops to 0.
	var hit_position: Vector2 = enemy_root.global_position
	var final_damage: int = hit_tuning.base_damage
	var is_back_hit: bool = false
	if enemy_root.has_method("take_dash_hit"):
		var result: Variant = enemy_root.take_dash_hit(hit_tuning.base_damage, _dash_direction)
		if result is Dictionary:
			final_damage = int(result.get("final_damage", hit_tuning.base_damage))
			is_back_hit = bool(result.get("is_back_hit", false))
	hit_landed.emit(enemy_root, final_damage, hit_position, _dash_direction, is_back_hit)

# ===== Trail =====

func _append_trail_point(p: Vector2) -> void:
	trail.add_point(p)
	# Keep the line bounded — drop oldest points once we exceed the cap.
	while trail.get_point_count() > tuning.trail_max_points:
		trail.remove_point(0)

# ===== Idle rotation =====

func _update_idle_rotation() -> void:
	if current_aim.length() <= 0.0:
		return
	rotation = lerp_angle(rotation, current_aim.angle(), tuning.idle_rotation_lerp)

# ===== Modifier API =====

func set_dash_distance_modifier(key: StringName, additive: float = 0.0, multiplicative: float = 1.0) -> void:
	_distance_mods[key] = {"additive": additive, "multiplicative": multiplicative}

func clear_dash_distance_modifier(key: StringName) -> void:
	_distance_mods.erase(key)

func set_dash_duration_modifier(key: StringName, additive: float = 0.0, multiplicative: float = 1.0) -> void:
	_duration_mods[key] = {"additive": additive, "multiplicative": multiplicative}

func clear_dash_duration_modifier(key: StringName) -> void:
	_duration_mods.erase(key)

func _compute_effective(base: float, mods: Dictionary, min_value: float) -> float:
	var additive_sum: float = 0.0
	var multiplicative_product: float = 1.0
	for entry in mods.values():
		additive_sum += float(entry.additive)
		multiplicative_product *= float(entry.multiplicative)
	return maxf(min_value, (base + additive_sum) * multiplicative_product)

# ===== Curve baking =====

const CURVE_SAMPLES: int = 64

func _bake_speed_curve() -> void:
	# Build a cumulative-integral table for `speed_curve` so we can resolve
	# "fraction of dash distance covered by time t" without per-frame integrals.
	_curve_baked.resize(CURVE_SAMPLES + 1)
	_curve_baked[0] = 0.0
	_curve_total_integral = 0.0
	if tuning.speed_curve == null:
		# Fallback: linear unit ramp. Keeps the dash functional even if the
		# curve resource is missing.
		for i in CURVE_SAMPLES + 1:
			_curve_baked[i] = float(i) / float(CURVE_SAMPLES)
		_curve_total_integral = 1.0
		return
	var curve: Curve = tuning.speed_curve
	for i in CURVE_SAMPLES:
		var t1: float = float(i) / float(CURVE_SAMPLES)
		var t2: float = float(i + 1) / float(CURVE_SAMPLES)
		var avg: float = absf(curve.sample(t1) + curve.sample(t2)) * 0.5
		_curve_total_integral += avg * (t2 - t1)
		_curve_baked[i + 1] = _curve_total_integral
	if _curve_total_integral <= 0.0:
		# Pathological curve — fall back to linear ramp.
		push_warning("Player: dash speed_curve integrates to <=0; falling back to linear.")
		for i in CURVE_SAMPLES + 1:
			_curve_baked[i] = float(i) / float(CURVE_SAMPLES)
		_curve_total_integral = 1.0

func _sample_baked_integral(t: float) -> float:
	var n: int = _curve_baked.size() - 1
	if n <= 0:
		return t
	var idx_f: float = clampf(t, 0.0, 1.0) * float(n)
	var i0: int = int(idx_f)
	var i1: int = mini(i0 + 1, n)
	var f: float = idx_f - float(i0)
	return lerpf(_curve_baked[i0], _curve_baked[i1], f)
