extends Control

## Visual feedback for the input system.
##
## - Touch swipe trail: a fading dot trail follows the active touch.
## - Aim line (M+KB and controller): a faint line from the player toward the
##   current aim direction. Hidden during touch — the swipe trail is its own
##   feedback.
##
## Drawn in a CanvasLayer / Control so coordinates are screen-space; world-space
## quantities (player position, aim direction) are projected via the viewport's
## canvas transform each frame.

const TRAIL_DOT_RADIUS: float = 3.0
const TRAIL_MIN_SPACING: float = 4.0
const AIM_LINE_WIDTH: float = 1.5
const AIM_LINE_COLOR := Color(1, 1, 1, 0.4)
const TRAIL_COLOR := Color(1, 1, 1, 0.6)
const TUNING_PATH := "res://resources/input_feedback.tres"

var tuning: FeedbackTuning
var _trail_points: Array[Vector2] = []
var _trail_times: Array[float] = []
var _show_aim_line: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	tuning = load(TUNING_PATH) as FeedbackTuning
	if tuning == null:
		push_error("InputFeedbackOverlay: failed to load tuning at %s; using defaults." % TUNING_PATH)
		tuning = FeedbackTuning.new()
	InputSystem.input_source_changed.connect(_on_source_changed)
	# Initialize aim-line visibility from current state.
	_show_aim_line = (InputSystem.current_source != InputSystem.InputSource.TOUCH)

func _on_source_changed(source: int) -> void:
	_show_aim_line = (source != InputSystem.InputSource.TOUCH)
	# Drop any stale trail when switching away from touch.
	if source != InputSystem.InputSource.TOUCH:
		_trail_points.clear()
		_trail_times.clear()

func _process(delta: float) -> void:
	# Track touch position into the trail buffer.
	if InputSystem.current_source == InputSystem.InputSource.TOUCH and InputSystem.is_touch_active():
		var pos: Vector2 = InputSystem.get_touch_current_pos()
		if _trail_points.is_empty() or pos.distance_to(_trail_points[-1]) >= TRAIL_MIN_SPACING:
			_trail_points.append(pos)
			_trail_times.append(0.0)

	# Age trail dots.
	var trail_dur: float = tuning.swipe_trail_duration
	for i in _trail_times.size():
		_trail_times[i] += delta
	while not _trail_times.is_empty() and _trail_times[0] > trail_dur:
		_trail_times.pop_front()
		_trail_points.pop_front()

	queue_redraw()

func _draw() -> void:
	# M+KB aim line: project world-space player + aim*length to screen.
	if _show_aim_line:
		var canvas_xform: Transform2D = get_viewport().get_canvas_transform()
		var player_world: Vector2 = InputSystem.player_world_position
		var aim_world: Vector2 = player_world + InputSystem.current_aim_direction * tuning.aim_line_length
		var player_screen: Vector2 = canvas_xform * player_world
		var aim_screen: Vector2 = canvas_xform * aim_world
		draw_line(player_screen, aim_screen, AIM_LINE_COLOR, AIM_LINE_WIDTH)

	# Touch trail.
	var trail_dur: float = tuning.swipe_trail_duration
	for i in _trail_points.size():
		var alpha_factor: float = 1.0 - (_trail_times[i] / trail_dur)
		alpha_factor = clampf(alpha_factor, 0.0, 1.0)
		var c := TRAIL_COLOR
		c.a *= alpha_factor
		draw_circle(_trail_points[i], TRAIL_DOT_RADIUS, c)
