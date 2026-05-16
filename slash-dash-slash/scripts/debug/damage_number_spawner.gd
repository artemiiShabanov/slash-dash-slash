extends Node2D

## Debug spawner. Connects to the player's `hit_landed` signal and instances a
## floating damage number at each contact, colored by the active slash's
## proc state (white = normal, element color = proc / combo).

const SCENE_PATH: String = "res://scenes/ui/damage_number.tscn"
const VERTICAL_OFFSET: float = -14.0

@export var damage_number_scene: PackedScene

func _ready() -> void:
	if damage_number_scene == null:
		damage_number_scene = load(SCENE_PATH) as PackedScene
	var player: Node = get_tree().get_first_node_in_group("player")
	if player == null:
		push_warning("DamageNumberSpawner: no node in 'player' group at ready.")
		return
	player.hit_landed.connect(_on_hit_landed.bind(player))

func _on_hit_landed(_target: Node, final_damage: int, position: Vector2, _dash_direction: Vector2, _is_back_hit: bool, player: Node) -> void:
	if damage_number_scene == null:
		return
	var color: Color = Color(1, 1, 1, 1)
	var is_crit: bool = false
	# Read the player's per-slash context to color/size the popup. Falls back
	# to plain white if a future spec removes the field.
	if "_current_slash_ctx" in player:
		var ctx = player._current_slash_ctx
		if ctx != null and ctx.procced_gems.size() > 0:
			color = ctx.flash_color
			is_crit = true
	var popup: DamageNumber = damage_number_scene.instantiate() as DamageNumber
	add_child(popup)
	popup.global_position = position + Vector2(0, VERTICAL_OFFSET)
	popup.setup(final_damage, color, is_crit)
