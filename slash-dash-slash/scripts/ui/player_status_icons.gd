extends Node2D

## Player-side status-effect strip. Reserved render surface: today nothing
## applies status to the player (only enemies are burned / slowed / stunned),
## so this draws nothing. Once a future enemy ability installs `_burns /
## _slows / _stuns / _vulns` arrays on the Player mirroring DummyEnemy's,
## `refresh()` reads them and renders icons.

const TUNING_PATH := "res://resources/hud_tuning.tres"

@export var tuning: HudTuning

var _follow_target: Node2D = null
var _base_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	top_level = true
	if tuning == null:
		tuning = load(TUNING_PATH) as HudTuning
		if tuning == null:
			tuning = HudTuning.new()
	# Sit below the stamina pips: stamina is at (0, -16); we offset further
	# down by status_offset relative to that anchor.
	_base_offset = Vector2(0, -16) + tuning.status_offset
	_follow_target = get_parent() as Node2D

func _process(_delta: float) -> void:
	if _follow_target != null:
		global_position = _follow_target.global_position + _base_offset

## Hook reserved for a future spec that installs status state on the Player.
## Today: no producers, so this is a no-op.
func refresh() -> void:
	queue_redraw()

func _draw() -> void:
	# Render nothing today. When status arrays land on the Player, iterate
	# them here and draw small icons spaced by tuning.pip_spacing.
	pass
