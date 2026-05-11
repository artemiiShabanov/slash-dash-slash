extends CharacterBody2D
class_name DummyEnemy

## Placeholder enemy for M3/M4 smoke tests.
## Stats sourced from `EnemyStats`; abilities dispatched per
## `enemy-ability-base`. Basic AI per `basic-enemy-ai`: chase the player at
## `move_speed`; when within `attack_range`, stop and attack at `attack_speed`.

const FLASH_FRONT: Color = Color(1.3, 1.3, 1.3, 1.0)
const FLASH_BACK: Color = Color(3.0, 3.0, 3.0, 1.0)
const FLASH_FADE_DURATION: float = 0.15

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

	# Refresh player ref if we lost it (player freed, reload, etc.).
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		if _player == null:
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

	# Chase or attack.
	if distance > stats.attack_range:
		# Out of range cancels any in-progress windup; chase forward.
		_is_winding_up = false
		_windup_remaining = 0.0
		var move_dir: Vector2 = to_player.normalized() if distance > 0.0 else Vector2.ZERO
		if stats.can_go_through_walls:
			global_position += move_dir * stats.move_speed * delta
		else:
			velocity = move_dir * stats.move_speed
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
	var final_damage: int = maxi(0, roundi(float(damage) * (1.0 - armor)))
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
