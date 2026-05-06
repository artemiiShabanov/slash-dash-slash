extends Node

## InputSystem autoload singleton.
##
## Abstracts dash input across touch, controller, and mouse+keyboard. Emits
## platform-agnostic signals; combat/movement consumers do not need to know
## which platform produced an input.
##
## Source switching is seamless: the first input from a different source takes
## over. The dash always uses the most recent non-zero aim direction at the
## moment of commit, so an input is never silently dropped.

# ===== Signals =====

## Discrete commit. Direction is normalized.
signal dash_requested(direction: Vector2)

## Continuous aim direction (normalized). Fires whenever the active source
## updates its aim — touch swipe in progress, controller stick, mouse motion.
signal aim_changed(direction: Vector2)

## Pause control pressed (Start on controller, Esc on M+KB, on-screen icon on touch).
signal pause_pressed

## Active input source changed.
signal input_source_changed(source: int)

# ===== Enums =====

enum InputSource { TOUCH, CONTROLLER, MOUSE_KEYBOARD, KEYBOARD }

# ===== Tunables =====

const TUNING_PATH := "res://resources/input_system.tres"
var tuning: InputTuning

# ===== Public state =====

var current_source: int = InputSource.MOUSE_KEYBOARD

## Most recent non-zero aim direction. Used as the dash direction at commit
## time when the instantaneous aim is zero (stick centered, cursor on player).
## Defaults to RIGHT as the first-frame fallback per spec.
var current_aim_direction: Vector2 = Vector2.RIGHT

## Buffered dash direction (single slot). Set when a dash input arrives while
## another dash is in progress; auto-emitted when dash_in_progress flips false.
var buffered_dash_direction: Variant = null

## Settable by gameplay code (the core-dash system, when implemented).
## Must be true while a dash is animating; false when free.
var dash_in_progress: bool = false:
	set(value):
		var was_in_progress: bool = dash_in_progress
		dash_in_progress = value
		# Flush buffer on the in-progress -> free transition.
		if was_in_progress and not value and buffered_dash_direction != null:
			var dir: Vector2 = buffered_dash_direction
			buffered_dash_direction = null
			dash_requested.emit(dir)

## World-space player position. Set each frame by the player so the input
## system can compute mouse-relative aim direction.
var player_world_position: Vector2 = Vector2.ZERO

# ===== Internal state =====

# Touch
var _touch_active: bool = false
var _touch_id: int = -1
var _touch_start_pos: Vector2 = Vector2.ZERO
var _touch_start_time: float = 0.0
var _touch_current_pos: Vector2 = Vector2.ZERO

# Aim emission (avoid spamming consumers with sub-degree changes)
var _last_emitted_aim: Vector2 = Vector2.ZERO
const AIM_EMIT_THRESHOLD: float = 0.01  # ~0.5 degrees

# ===== Lifecycle =====

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	tuning = load(TUNING_PATH) as InputTuning
	if tuning == null:
		push_error("InputSystem: failed to load tuning at %s; using defaults." % TUNING_PATH)
		tuning = InputTuning.new()

func _process(_delta: float) -> void:
	# Continuous aim tracking for the active source.
	match current_source:
		InputSource.TOUCH:
			pass  # handled inside InputEventScreenDrag
		InputSource.CONTROLLER:
			_update_aim_from_controller()
		InputSource.MOUSE_KEYBOARD:
			_update_aim_from_mouse()
		InputSource.KEYBOARD:
			_update_aim_from_keyboard()

func _unhandled_input(event: InputEvent) -> void:
	# --- Touch ---
	if event is InputEventScreenTouch:
		_handle_touch(event)
		return
	if event is InputEventScreenDrag:
		_handle_drag(event)
		return

	# --- Mouse + keyboard ---
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_switch_source(InputSource.MOUSE_KEYBOARD)
			_commit_dash()
		return
	if event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and not key.echo:
			match key.keycode:
				KEY_ESCAPE:
					pause_pressed.emit()
				KEY_SPACE:
					_switch_source(InputSource.KEYBOARD)
					_commit_dash()
				KEY_W, KEY_A, KEY_S, KEY_D, \
				KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT:
					_switch_source(InputSource.KEYBOARD)
		return

	# --- Controller ---
	if event is InputEventJoypadButton:
		var jb := event as InputEventJoypadButton
		if jb.pressed:
			match jb.button_index:
				# All four face buttons commit a dash.
				JOY_BUTTON_A, JOY_BUTTON_B, JOY_BUTTON_X, JOY_BUTTON_Y:
					_switch_source(InputSource.CONTROLLER)
					_commit_dash()
				JOY_BUTTON_START:
					pause_pressed.emit()
		return
	if event is InputEventJoypadMotion:
		var jm := event as InputEventJoypadMotion
		if (jm.axis == JOY_AXIS_LEFT_X or jm.axis == JOY_AXIS_LEFT_Y) \
				and absf(jm.axis_value) > tuning.controller_stick_deadzone:
			_switch_source(InputSource.CONTROLLER)
		return

# ===== Touch =====

func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		# First-touch ownership; additional touches ignored until lift.
		if _touch_active:
			return
		_touch_active = true
		_touch_id = event.index
		_touch_start_pos = event.position
		_touch_current_pos = event.position
		_touch_start_time = _now()
		_switch_source(InputSource.TOUCH)
		return

	# Release.
	if event.index != _touch_id:
		return
	var release_pos: Vector2 = event.position
	var elapsed: float = _now() - _touch_start_time
	var swipe_vec: Vector2 = release_pos - _touch_start_pos
	var distance: float = swipe_vec.length()
	_touch_active = false
	_touch_id = -1
	if distance >= tuning.swipe_min_distance and elapsed <= tuning.swipe_max_duration:
		var dir: Vector2 = swipe_vec.normalized()
		_set_aim(dir)
		_commit_dash_with_direction(dir)
	# Else: rejected silently. The trail visualization still draws.

func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index != _touch_id:
		return
	_touch_current_pos = event.position
	var delta_vec: Vector2 = _touch_current_pos - _touch_start_pos
	if delta_vec.length() > 0.01:
		_set_aim(delta_vec.normalized())

# ===== Controller =====

func _update_aim_from_controller() -> void:
	var raw_x: float = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	var raw_y: float = Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	var raw := Vector2(raw_x, raw_y)
	if raw.length() > tuning.controller_stick_deadzone:
		_set_aim(raw.normalized())

# ===== Keyboard (8-dir aim) =====

func _update_aim_from_keyboard() -> void:
	var x: float = 0.0
	var y: float = 0.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		x += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		x -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		y += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		y -= 1.0
	var v := Vector2(x, y)
	if v.length() > 0.01:
		# 8-dir aim: any combination yields one of 8 unit vectors after normalize.
		_set_aim(v.normalized())

# ===== Mouse =====

func _update_aim_from_mouse() -> void:
	var mouse_world: Vector2 = _get_mouse_world_position()
	var delta: Vector2 = mouse_world - player_world_position
	if delta.length() > 0.01:
		_set_aim(delta.normalized())

func _get_mouse_world_position() -> Vector2:
	var vp := get_viewport()
	if vp == null:
		return Vector2.ZERO
	return vp.get_canvas_transform().affine_inverse() * vp.get_mouse_position()

# ===== Commit & buffering =====

func _commit_dash() -> void:
	_commit_dash_with_direction(current_aim_direction)

func _commit_dash_with_direction(dir: Vector2) -> void:
	# Fall back to last-known aim if instantaneous direction is zero.
	if dir == Vector2.ZERO:
		dir = current_aim_direction
		if dir == Vector2.ZERO:
			dir = Vector2.RIGHT
	if dash_in_progress:
		# Most-recent overwrite.
		buffered_dash_direction = dir
	else:
		dash_requested.emit(dir)

# ===== Source switching =====

func _switch_source(new_source: int) -> void:
	if new_source == current_source:
		return
	current_source = new_source
	input_source_changed.emit(new_source)

# ===== Aim emission =====

func _set_aim(dir: Vector2) -> void:
	current_aim_direction = dir
	if dir.distance_to(_last_emitted_aim) >= AIM_EMIT_THRESHOLD:
		_last_emitted_aim = dir
		aim_changed.emit(dir)

# ===== Public helpers (used by feedback overlay) =====

func is_touch_active() -> bool:
	return _touch_active

func get_touch_current_pos() -> Vector2:
	return _touch_current_pos

func get_touch_start_pos() -> Vector2:
	return _touch_start_pos

# ===== Time =====

func _now() -> float:
	return Time.get_ticks_msec() / 1000.0
