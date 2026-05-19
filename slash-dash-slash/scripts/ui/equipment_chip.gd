extends CanvasLayer
class_name EquipmentChip

## Top-left equipment readout. Built once at scene `_ready` from the Player
## node passed into `populate(player)`. Four icon groups separated by short
## vertical dividers:
##   - sword icon
##   - amulet icon
##   - weapon gem slots (one frame per equipped_sword.gem_slot_count;
##     first N filled with gem icons, rest empty)
##   - amulet gem slot (one frame; filled when equipped_amulet_gem != null)
##
## Styled via the project default theme (boardroom_black panel + dot_matrix_green
## borders) so it reads as part of the CRT-terminal wash.

const TUNING_PATH := "res://resources/hud_tuning.tres"
const SLOT_FRAME_SCRIPT := preload("res://scripts/ui/slot_frame.gd")
const PALETTE_SWORD_FALLBACK: Color = Color(0.34, 0.78, 0.42, 1.0)   # dot_matrix_green
const PALETTE_AMULET_FALLBACK: Color = Color(0.94, 0.93, 0.86, 1.0)  # bone_white
const PALETTE_AMULET_GEM_FALLBACK: Color = Color(0.94, 0.93, 0.86, 1.0)

@export var tuning: HudTuning

@onready var _row: HBoxContainer = $Panel/Row

var _player: Node = null

func _ready() -> void:
	if tuning == null:
		tuning = load(TUNING_PATH) as HudTuning
		if tuning == null:
			tuning = HudTuning.new()
	$Panel.position = tuning.chip_padding
	_row.add_theme_constant_override("separation", tuning.chip_separator_width)
	# Auto-bind to the player on the next frame so direct-scene placements
	# (m3_combat_demo) don't need a separate binder script. Callers can still
	# `populate(player)` explicitly to override.
	call_deferred("_auto_bind")

func _auto_bind() -> void:
	if _player != null:
		return
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		populate(player)

## Build the chip from the given player's equipment. Subscribes to an
## `equipment_changed` signal if present (no producer today) so a future
## hot-swap path can refresh the chip.
func populate(player: Node) -> void:
	_player = player
	if player.has_signal("equipment_changed") and not player.equipment_changed.is_connected(_on_equipment_changed):
		player.equipment_changed.connect(_on_equipment_changed)
	_rebuild()

func _on_equipment_changed() -> void:
	_rebuild()

func _rebuild() -> void:
	for child in _row.get_children():
		child.queue_free()
	if _player == null:
		return
	# Group 1: sword icon.
	_row.add_child(_make_slot(
		_player.equipped_sword.icon if _player.equipped_sword != null else null,
		PALETTE_SWORD_FALLBACK,
		_first_letter(_player.equipped_sword.display_name if _player.equipped_sword != null else "S"),
	))
	# Group 2: amulet icon.
	_row.add_child(_make_slot(
		_player.equipped_amulet.icon if _player.equipped_amulet != null else null,
		PALETTE_AMULET_FALLBACK,
		_first_letter(_player.equipped_amulet.display_name if _player.equipped_amulet != null else "A"),
	))
	# Group 3: weapon gem slots. Visualizes the sword's capacity even when
	# fewer gems are equipped (empty frames make the headroom legible).
	_row.add_child(_make_separator())
	var slot_count: int = _player.equipped_sword.gem_slot_count if _player.equipped_sword != null else 0
	var gems: Array = _player.equipped_weapon_gems
	for i in slot_count:
		var slot := SLOT_FRAME_SCRIPT.new()
		slot.tuning = tuning
		_row.add_child(slot)
		if i < gems.size() and gems[i] != null:
			var gem = gems[i]
			slot.set_filled(
				Element.icon(gem.element),
				Element.color(gem.element),
				Element.kind_name(gem.element),
			)
		else:
			slot.set_empty()
	# Group 4: amulet gem slot.
	_row.add_child(_make_separator())
	var amulet_slot := SLOT_FRAME_SCRIPT.new()
	amulet_slot.tuning = tuning
	_row.add_child(amulet_slot)
	if _player.equipped_amulet_gem != null:
		amulet_slot.set_filled(
			_player.equipped_amulet_gem.icon,
			PALETTE_AMULET_GEM_FALLBACK,
			_first_letter(_player.equipped_amulet_gem.display_name),
		)
	else:
		amulet_slot.set_empty()

func _make_slot(texture: Texture2D, fallback_color: Color, fallback_letter: String) -> Control:
	var slot := SLOT_FRAME_SCRIPT.new()
	slot.tuning = tuning
	# Defer fill until after _ready resolves tuning + sizing.
	slot.call_deferred("set_filled", texture, fallback_color, fallback_letter)
	return slot

func _make_separator() -> VSeparator:
	var sep := VSeparator.new()
	sep.custom_minimum_size = Vector2(tuning.chip_separator_width, float(tuning.icon_size))
	return sep

func _first_letter(s: String) -> String:
	return s.substr(0, 1) if s.length() > 0 else ""
