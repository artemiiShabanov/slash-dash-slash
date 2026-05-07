extends Node2D

## M1 demo scene controller.
##
## Empty room with walls; a placeholder player whose only behavior is logging
## InputSystem events. Lets us smoke-test the input spec without depending on
## core-dash being implemented.

@onready var player: Node2D = $Player

func _ready() -> void:
	InputSystem.dash_requested.connect(_on_dash_requested)
	InputSystem.aim_changed.connect(_on_aim_changed)
	InputSystem.pause_pressed.connect(_on_pause_pressed)
	InputSystem.input_source_changed.connect(_on_source_changed)
	print("[M1 input demo] Ready. Try: swipe (touch), stick + face button (controller), mouse + click (M+KB), or WASD/arrows + Space (keyboard only).")

func _process(_delta: float) -> void:
	# Provide world-space player position so InputSystem can compute mouse aim.
	InputSystem.player_world_position = player.global_position

func _on_dash_requested(direction: Vector2) -> void:
	print("[M1] dash_requested  dir=%s  source=%s" % [direction, _source_name(InputSystem.current_source)])

func _on_aim_changed(_direction: Vector2) -> void:
	# High-frequency; left silent by default. Uncomment for verbose debugging.
	# print("[M1] aim_changed dir=%s" % _direction)
	pass

func _on_pause_pressed() -> void:
	print("[M1] pause_pressed")

func _on_source_changed(source: int) -> void:
	print("[M1] input_source_changed -> %s" % _source_name(source))

func _source_name(source: int) -> String:
	match source:
		InputSystem.InputSource.TOUCH: return "TOUCH"
		InputSystem.InputSource.CONTROLLER: return "CONTROLLER"
		InputSystem.InputSource.MOUSE_KEYBOARD: return "MOUSE_KEYBOARD"
		InputSystem.InputSource.KEYBOARD: return "KEYBOARD"
		_: return "UNKNOWN"
