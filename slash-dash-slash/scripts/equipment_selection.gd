extends Control

## Equipment selection scene controller.
##
## Hardcoded roster paths for v1 (loaded as Resources at _ready). Future
## unlock-conditions specs will replace these with a discovery / catalog
## system filtered by unlocked-state.
##
## Each card is a focusable Button with a transparent-overlay RichTextLabel
## for multi-line name + description. Selection is tracked per column;
## clicking or pressing a card updates the index and re-applies highlights.
## "Start Run" writes the chosen resources to RunState and changes scene.

const SWORD_PATHS: Array[String] = [
	"res://resources/equipment/swords/letter_opener.tres",
	"res://resources/equipment/swords/executive_katana.tres",
]
const AMULET_PATHS: Array[String] = [
	"res://resources/equipment/amulets/id_lanyard.tres",
	"res://resources/equipment/amulets/field_managers_belt.tres",
]
const GAMEPLAY_SCENE: String = "res://scenes/demos/m3_combat_demo.tscn"

const CARD_SIZE: Vector2 = Vector2(240, 125)
const DIM_MODULATE: Color = Color(0.55, 0.55, 0.55, 1)
const ACTIVE_MODULATE: Color = Color(1, 1, 1, 1)

@onready var sword_column: VBoxContainer = $Margins/Layout/Columns/SwordColumn
@onready var amulet_column: VBoxContainer = $Margins/Layout/Columns/AmuletColumn
@onready var start_button: Button = $Margins/Layout/StartButton

var _sword_resources: Array[SwordStats] = []
var _amulet_resources: Array[AmuletStats] = []
var _sword_cards: Array[Button] = []
var _amulet_cards: Array[Button] = []
var _selected_sword_index: int = 0
var _selected_amulet_index: int = 0

func _ready() -> void:
	RunState.reset()
	_populate_swords()
	_populate_amulets()
	_refresh_highlights()
	start_button.pressed.connect(_on_start_pressed)
	# Focus the first sword card so D-pad / keyboard nav works on enter.
	if _sword_cards.size() > 0:
		_sword_cards[0].grab_focus()

func _populate_swords() -> void:
	for path in SWORD_PATHS:
		var res: SwordStats = load(path) as SwordStats
		if res == null:
			push_error("equipment_selection: failed to load sword %s" % path)
			continue
		_sword_resources.append(res)
		var idx: int = _sword_resources.size() - 1
		var card: Button = _make_card(res.display_name, res.description)
		card.pressed.connect(func() -> void: _select_sword(idx))
		_sword_cards.append(card)
		sword_column.add_child(card)

func _populate_amulets() -> void:
	for path in AMULET_PATHS:
		var res: AmuletStats = load(path) as AmuletStats
		if res == null:
			push_error("equipment_selection: failed to load amulet %s" % path)
			continue
		_amulet_resources.append(res)
		var idx: int = _amulet_resources.size() - 1
		var card: Button = _make_card(res.display_name, res.description)
		card.pressed.connect(func() -> void: _select_amulet(idx))
		_amulet_cards.append(card)
		amulet_column.add_child(card)

## Build a clickable, focusable card using the shared `PaperStyle` helper.
func _make_card(name_text: String, desc_text: String) -> Button:
	return PaperStyle.make_paper_card(name_text, desc_text, CARD_SIZE)

func _select_sword(idx: int) -> void:
	_selected_sword_index = idx
	_refresh_highlights()

func _select_amulet(idx: int) -> void:
	_selected_amulet_index = idx
	_refresh_highlights()

## Selected card draws at full brightness; the rest dim. Cheap, readable.
func _refresh_highlights() -> void:
	for i in _sword_cards.size():
		_sword_cards[i].modulate = ACTIVE_MODULATE if i == _selected_sword_index else DIM_MODULATE
	for i in _amulet_cards.size():
		_amulet_cards[i].modulate = ACTIVE_MODULATE if i == _selected_amulet_index else DIM_MODULATE

func _on_start_pressed() -> void:
	if _selected_sword_index >= 0 and _selected_sword_index < _sword_resources.size():
		RunState.chosen_sword = _sword_resources[_selected_sword_index]
	if _selected_amulet_index >= 0 and _selected_amulet_index < _amulet_resources.size():
		RunState.chosen_amulet = _amulet_resources[_selected_amulet_index]
	get_tree().change_scene_to_file(GAMEPLAY_SCENE)
