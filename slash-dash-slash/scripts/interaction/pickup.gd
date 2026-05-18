extends Area2D
class_name Pickup

## Base magnetized pickup. Idles in place until the player enters
## `tuning.attract_radius`; then lerps toward the player and consumes itself
## on body contact. Subclasses override `_apply_payload`.
##
## Layer: PICKUP_LAYER = 32. Mask: 8 (player body) so `body_entered` fires.

const PICKUP_LAYER: int = 32
const PLAYER_BODY_MASK: int = 8

@export var tuning: InteractionTuning

var _player: Node = null
var _seeking: bool = false
var _age: float = 0.0

## Initial scatter velocity (pixels/sec), set by the spawner before add_child.
## Drifts the pickup outward during the pre-seek window, decays via
## tuning.scatter_friction, then zeroes when seeking starts.
var velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Enforce layer/mask at runtime so scene authoring mistakes don't break
	# detection silently.
	collision_layer = PICKUP_LAYER
	collision_mask = PLAYER_BODY_MASK
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)
	if tuning == null:
		tuning = load("res://resources/interaction_tuning.tres") as InteractionTuning
		if tuning == null:
			push_warning("Pickup: failed to load default InteractionTuning; using class defaults.")
			tuning = InteractionTuning.new()

func _physics_process(delta: float) -> void:
	_age += delta
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		if _player == null:
			return
	var to_player: Vector2 = _player.global_position - global_position
	if not _seeking:
		# Integrate scatter velocity and decay it — drops visibly fly out
		# from the spawner before they magnet.
		if velocity.length_squared() > 0.0001:
			global_position += velocity * delta
			velocity = velocity.lerp(Vector2.ZERO, clampf(tuning.scatter_friction * delta, 0.0, 1.0))
		# Hold for seek_delay so drops are visibly scattered before they
		# magnet. Consumption is also gated on `_seeking` (see
		# _on_body_entered) so direct overlap during this window doesn't
		# steal the moment.
		if _age >= tuning.seek_delay and to_player.length() <= tuning.attract_radius:
			_seeking = true
			velocity = Vector2.ZERO
	if _seeking:
		var t: float = clampf(tuning.lerp_factor * delta, 0.0, 1.0)
		global_position = global_position.lerp(_player.global_position, t)

func _on_body_entered(body: Node) -> void:
	# Player body is on layer 8; mask ensures only the player triggers this.
	# Consumption is gated on `_seeking` — pickups can only be collected via
	# the magnet phase. Direct dash-through during the pre-seek window is
	# intentionally a no-op so the heal/loot moment has weight.
	if not is_instance_valid(body):
		return
	if not _seeking:
		return
	_apply_payload(body)
	queue_free()

## Override in subclasses. Default no-op.
func _apply_payload(_player_node: Node) -> void:
	pass
