class_name WaterCoolerInteraction
extends Interaction

## Single-use shrine: on first dash-into, spawn `drop_count` HealPickups
## scattered within `scatter_radius`, then mark the interactable consumed
## and tint it `depleted_color`.

@export var heal_pickup_scene: PackedScene
@export var drop_count: int = 3
@export var scatter_radius: float = 14.0
@export var scatter_speed_min: float = 80.0
@export var scatter_speed_max: float = 140.0
@export var depleted_color: Color = Color(0.4, 0.45, 0.55, 1.0)

func on_dash_into(_player: Node, interactable: Node) -> void:
	if interactable == null or not is_instance_valid(interactable):
		return
	if "consumed" in interactable and interactable.consumed:
		return
	interactable.consumed = true
	# Dim the cooler's visual to signal spent state. We tint any direct child
	# named "Visual" — common convention across the codebase.
	var visual: Node = interactable.get_node_or_null("Visual")
	if visual != null and "modulate" in visual:
		visual.modulate = depleted_color
	if heal_pickup_scene == null:
		push_warning("WaterCoolerInteraction: heal_pickup_scene not set; no drops will spawn.")
		return
	var parent: Node = interactable.get_parent()
	if parent == null:
		parent = interactable.get_tree().current_scene
	# Spawn point captured now (interactable may move? — it won't, but keeps
	# the deferred closure self-contained).
	var origin: Vector2 = interactable.global_position
	for i in drop_count:
		var pickup: Node2D = heal_pickup_scene.instantiate() as Node2D
		if pickup == null:
			continue
		var angle: float = randf() * TAU
		var radius: float = randf_range(scatter_radius * 0.4, scatter_radius)
		var dir: Vector2 = Vector2.from_angle(angle)
		var spawn_pos: Vector2 = origin + dir * radius
		# Give each drop an outward velocity so they visibly fly out of the
		# cooler during the pre-seek window. Pickup.velocity decays via
		# tuning.scatter_friction.
		var speed: float = randf_range(scatter_speed_min, scatter_speed_max)
		pickup.velocity = dir * speed
		# Defer the add_child: this can be called from inside an area_entered
		# callback (physics flush), and Godot forbids adding Area2D children
		# during flush. Setting position before add is safe because the new
		# node isn't in the tree yet.
		pickup.position = spawn_pos
		parent.add_child.call_deferred(pickup)
