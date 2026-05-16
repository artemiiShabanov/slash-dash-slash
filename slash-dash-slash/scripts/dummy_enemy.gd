extends CharacterBody2D
class_name DummyEnemy

## Placeholder enemy for M3/M4 smoke tests.
## Stats sourced from `EnemyStats`; abilities dispatched per
## `enemy-ability-base`. Basic AI per `basic-enemy-ai`: chase the player at
## `move_speed`; when within `attack_range`, stop and attack at `attack_speed`.
##
## Gem-status interface (per `weapon-gem-roster`):
##   apply_burn / apply_slow / apply_stun / apply_vulnerability / apply_knockback
## Burns, slows, stuns, vulns are stored as parallel instances (each with its
## own timer) so successive procs stack.

const FLASH_FRONT: Color = Color(1.3, 1.3, 1.3, 1.0)
const FLASH_BACK: Color = Color(3.0, 3.0, 3.0, 1.0)
const FLASH_FADE_DURATION: float = 0.15
const SLOW_TINT: Color = Color(0.7, 0.85, 1.0)
const SLOW_STACK_CAP: float = 0.95  # never reaches 100% — stun's job.

@export var stats: EnemyStats

## Direction this enemy is facing. Per-instance runtime state, mutated by AI
## during chase; serves as the input to armor-direction's side calc.
@export var facing: Vector2 = Vector2.RIGHT

@onready var visual: Polygon2D = $Visual
@onready var arrow: Polygon2D = $Arrow

var health: int = 0
var _flash_tween: Tween = null
var _player: Node = null

# Attack phases: windup (in range, building up to fire) → fire → cooldown
# (post-attack, can't start another windup until 0). Out-of-range cancels any
# in-progress windup; cooldown keeps ticking regardless.
var _windup_remaining: float = 0.0
var _cooldown_remaining: float = 0.0
var _is_winding_up: bool = false

# ===== Gem-status state =====

# Each entry: { damage_per_tick: float, tick_interval: float,
#               time_to_next_tick: float, time_remaining: float, residual: float }
var _burns: Array = []
# Each entry: { slow_pct: float, time_remaining: float }
var _slows: Array = []
# Each entry: { time_remaining: float }
var _stuns: Array = []
# Each entry: { damage_mult: float, time_remaining: float }
var _vulns: Array = []

func _ready() -> void:
	add_to_group("enemy")
	if stats == null:
		push_warning("DummyEnemy: stats is null; using default EnemyStats.")
		stats = EnemyStats.new()
	health = stats.max_health
	visual.modulate = Color(1, 1, 1, 1)
	if facing.length() > 0.0:
		arrow.rotation = facing.angle()
	_dispatch_on_spawn()

func _physics_process(delta: float) -> void:
	_dispatch_on_tick(delta)
	# Cooldown ticks regardless of range. Windup ticks only while active.
	_cooldown_remaining = maxf(0.0, _cooldown_remaining - delta)
	if _is_winding_up:
		_windup_remaining = maxf(0.0, _windup_remaining - delta)

	# Tick status effects (may queue_free us via burn damage).
	_tick_status(delta)
	if not is_instance_valid(self):
		return

	# Refresh player ref if we lost it (player freed, reload, etc.).
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		if _player == null:
			return

	# Stun overrides everything: stand still, drop windup, don't chase.
	if _is_stunned():
		_is_winding_up = false
		_windup_remaining = 0.0
		velocity = Vector2.ZERO
		if not stats.can_go_through_walls:
			move_and_slide()
		return

	var to_player: Vector2 = _player.global_position - global_position
	var distance: float = to_player.length()

	# Rotate facing toward player, rate-limited by stats.rotation_speed.
	if distance > 0.0:
		var target_dir: Vector2 = to_player.normalized()
		if stats.rotation_speed <= 0.0:
			facing = target_dir
		else:
			var current_angle: float = facing.angle()
			var target_angle: float = target_dir.angle()
			var diff: float = wrapf(target_angle - current_angle, -PI, PI)
			var max_step: float = stats.rotation_speed * delta
			var step: float = clampf(diff, -max_step, max_step)
			facing = Vector2.RIGHT.rotated(current_angle + step)
		arrow.rotation = facing.angle()

	var speed_mult: float = _slow_multiplier()
	var effective_speed: float = stats.move_speed * speed_mult

	# Chase or attack.
	if distance > stats.attack_range:
		# Out of range cancels any in-progress windup; chase forward.
		_is_winding_up = false
		_windup_remaining = 0.0
		var move_dir: Vector2 = to_player.normalized() if distance > 0.0 else Vector2.ZERO
		if stats.can_go_through_walls:
			global_position += move_dir * effective_speed * delta
		else:
			velocity = move_dir * effective_speed
			move_and_slide()
	else:
		# In range — stop, then run the windup→fire→cooldown cycle.
		velocity = Vector2.ZERO
		if not stats.can_go_through_walls:
			move_and_slide()
		# Start a windup if ready and not already winding up.
		if not _is_winding_up and _cooldown_remaining <= 0.0:
			_is_winding_up = true
			_windup_remaining = maxf(0.0, stats.windup_duration)
		# Fire when the windup completes while still in range.
		if _is_winding_up and _windup_remaining <= 0.0:
			_do_attack()
			_is_winding_up = false
			_cooldown_remaining = 1.0 / maxf(0.01, stats.attack_speed)

func _do_attack() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if _player.has_method("take_damage"):
		_player.take_damage(stats.damage)

## Player calls this on contact during a slash dash. Side is decided by the
## sign of the dot product between the dash direction and the enemy's facing.
## Returns the resolved hit info so the player can populate `hit_landed`
## without recomputing the side itself.
func take_dash_hit(damage: int, dash_direction: Vector2) -> Dictionary:
	var is_back_hit: bool = facing.length() > 0.0 and dash_direction.dot(facing) > 0.0
	var armor: float = stats.armor_back if is_back_hit else stats.armor_front
	var armored: int = maxi(0, roundi(float(damage) * (1.0 - armor)))
	# Vulnerability multiplier (product of live stacks) applies after armor.
	var final_damage: int = roundi(float(armored) * _vulnerability_product())
	health -= final_damage
	_flash(FLASH_BACK if is_back_hit else FLASH_FRONT)
	_dispatch_on_hit(final_damage, dash_direction, is_back_hit)
	if health <= 0:
		_dispatch_on_death()
		queue_free()
	return {"final_damage": final_damage, "is_back_hit": is_back_hit}

func _flash(color: Color) -> void:
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	visual.modulate = color
	_flash_tween = create_tween()
	_flash_tween.tween_property(visual, "modulate", Color(1, 1, 1, 1), FLASH_FADE_DURATION)

# ===== Gem-status: apply methods =====

func apply_burn(damage_per_tick: float, tick_interval: float, duration: float) -> void:
	_burns.append({
		"damage_per_tick": damage_per_tick,
		"tick_interval": tick_interval,
		"time_to_next_tick": tick_interval,
		"time_remaining": duration,
		"residual": 0.0,
	})

func apply_slow(slow_pct: float, duration: float) -> void:
	_slows.append({"slow_pct": clampf(slow_pct, 0.0, 1.0), "time_remaining": duration})

func apply_stun(duration: float) -> void:
	_stuns.append({"time_remaining": duration})

func apply_vulnerability(damage_mult: float, duration: float) -> void:
	_vulns.append({"damage_mult": damage_mult, "time_remaining": duration})

func apply_knockback(direction: Vector2, distance: float) -> void:
	if direction.length() > 0.0:
		global_position += direction.normalized() * distance

# ===== Gem-status: tick =====

func _tick_status(delta: float) -> void:
	# Burns — fractional damage accumulates via per-instance residual so a
	# 0.2/tick burn against base=2 eventually deals 1 HP rather than rounding
	# silently to 0.
	var i: int = _burns.size() - 1
	while i >= 0:
		var b: Dictionary = _burns[i]
		b.time_to_next_tick -= delta
		while b.time_to_next_tick <= 0.0 and b.time_remaining > 0.0:
			var raw: float = b.damage_per_tick + b.residual
			var whole: int = int(floor(raw))
			b.residual = raw - float(whole)
			if whole > 0:
				_apply_burn_damage(whole)
				if not is_instance_valid(self):
					return  # queue_free hit; bail.
			b.time_to_next_tick += b.tick_interval
		b.time_remaining -= delta
		if b.time_remaining <= 0.0:
			_burns.remove_at(i)
		i -= 1
	_prune_timed(_slows, delta)
	_prune_timed(_stuns, delta)
	_prune_timed(_vulns, delta)
	_apply_status_tint()

func _prune_timed(arr: Array, delta: float) -> void:
	var i: int = arr.size() - 1
	while i >= 0:
		arr[i].time_remaining -= delta
		if arr[i].time_remaining <= 0.0:
			arr.remove_at(i)
		i -= 1

func _apply_burn_damage(damage: int) -> void:
	health -= damage
	_dispatch_on_hit(damage, Vector2.ZERO, false)
	if health <= 0:
		_dispatch_on_death()
		queue_free()

func _is_stunned() -> bool:
	return _stuns.size() > 0

func _slow_multiplier() -> float:
	if _slows.is_empty():
		return 1.0
	var sum: float = 0.0
	for s in _slows:
		sum += float(s.slow_pct)
	return 1.0 - clampf(sum, 0.0, SLOW_STACK_CAP)

func _vulnerability_product() -> float:
	var p: float = 1.0
	for v in _vulns:
		p *= float(v.damage_mult)
	return p

# Status-tint priority: stun > burn > slow > white. The hit flash tween still
# wins briefly when active; status tint reasserts on the next physics frame.
func _apply_status_tint() -> void:
	if _flash_tween != null and _flash_tween.is_valid():
		return
	if _is_stunned():
		visual.modulate = Element.color(Element.Kind.ICE)
	elif _burns.size() > 0:
		visual.modulate = Element.color(Element.Kind.FIRE)
	elif _slows.size() > 0:
		visual.modulate = SLOW_TINT
	else:
		visual.modulate = Color(1, 1, 1, 1)

# ===== Ability dispatchers =====

func _dispatch_on_spawn() -> void:
	if stats == null:
		return
	for ability in stats.abilities:
		if ability != null:
			ability.on_spawn(self)

func _dispatch_on_tick(delta: float) -> void:
	if stats == null:
		return
	for ability in stats.abilities:
		if ability != null:
			ability.on_tick(self, delta)

func _dispatch_on_hit(damage: int, dash_direction: Vector2, is_back_hit: bool) -> void:
	if stats == null:
		return
	for ability in stats.abilities:
		if ability != null:
			ability.on_hit(self, damage, dash_direction, is_back_hit)

func _dispatch_on_death() -> void:
	if stats == null:
		return
	for ability in stats.abilities:
		if ability != null:
			ability.on_death(self)
