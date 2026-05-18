extends Node2D

## Debug spawner. Connects to the player's `hit_landed` and `damaged` signals
## and instances a floating damage number at each event. Damage popups are
## white (or element-tinted on a procced slash); heal popups (negative
## `damaged` amounts emitted by Vampiric / HealPickup as a placeholder until
## a real `healed` signal exists) render green at the player's position.

const SCENE_PATH: String = "res://scenes/ui/damage_number.tscn"
const VERTICAL_OFFSET: float = -14.0
const HEAL_COLOR: Color = Color(0.40, 0.95, 0.50, 1.0)

@export var damage_number_scene: PackedScene

func _ready() -> void:
	if damage_number_scene == null:
		damage_number_scene = load(SCENE_PATH) as PackedScene
	var player: Node = get_tree().get_first_node_in_group("player")
	if player == null:
		push_warning("DamageNumberSpawner: no node in 'player' group at ready.")
		return
	player.hit_landed.connect(_on_hit_landed.bind(player))
	if player.has_signal("damaged"):
		player.damaged.connect(_on_player_damaged.bind(player))

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
	_spawn_popup(final_damage, position + Vector2(0, VERTICAL_OFFSET), color, is_crit)

func _on_player_damaged(amount: int, _source: Node, player: Node) -> void:
	# Real damage is already flashed on the player visually; we only render a
	# popup for the heal placeholder (negative amount) so the heal moment is
	# legible during testing. When a proper `healed` signal lands this can
	# narrow to that signal.
	if amount >= 0:
		return
	if damage_number_scene == null or player == null or not is_instance_valid(player):
		return
	_spawn_popup(absi(amount), player.global_position + Vector2(0, VERTICAL_OFFSET), HEAL_COLOR, false)

func _spawn_popup(amount: int, world_position: Vector2, color: Color, is_crit: bool) -> void:
	var popup: DamageNumber = damage_number_scene.instantiate() as DamageNumber
	add_child(popup)
	popup.global_position = world_position
	popup.setup(amount, color, is_crit)
