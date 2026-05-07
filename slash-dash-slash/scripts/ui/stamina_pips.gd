extends Node2D

## Stamina pips.
##
## A row of N small circles drawn above a parent that emits
## `stamina_changed(current: int, max: int)`. Drained pips disappear
## immediately on slash; regenerated pips fade back in over `fade_in_duration`.
##
## Top-level so the row tracks the parent's position but ignores its rotation
## — the pips always read horizontally regardless of how the parent is facing.

@export var offset: Vector2 = Vector2(0, -16)
@export var spacing: float = 5.0
@export var radius: float = 1.8
@export var filled_color: Color = Color(0.34, 0.78, 0.42, 1.0)  # dot_matrix_green
@export var empty_color: Color = Color(0.45, 0.42, 0.38, 0.5)   # dim shadow_grey
@export var fade_in_duration: float = 0.15

var _pip_alphas: Array[float] = []
var _max_stamina: int = 0
var _current_stamina: int = 0
var _follow_target: Node2D = null

func _ready() -> void:
	top_level = true
	_follow_target = get_parent() as Node2D
	if _follow_target != null and _follow_target.has_signal("stamina_changed"):
		_follow_target.stamina_changed.connect(_on_stamina_changed)

func _process(_delta: float) -> void:
	if _follow_target != null:
		global_position = _follow_target.global_position + offset

func _on_stamina_changed(current: int, maximum: int) -> void:
	# Resize the alpha array to match the (possibly new) max.
	if maximum != _max_stamina:
		_max_stamina = maximum
		_pip_alphas.resize(_max_stamina)
		for i in _max_stamina:
			_pip_alphas[i] = 1.0 if i < current else 0.0

	# Diff each pip slot: drained pips clear instantly; regenerated pips fade in.
	for i in _max_stamina:
		var should_fill: bool = i < current
		var was_filled: bool = i < _current_stamina
		if should_fill and not was_filled:
			_tween_pip(i, 1.0)
		elif not should_fill and was_filled:
			# Instant drain.
			_pip_alphas[i] = 0.0
	_current_stamina = current
	queue_redraw()

func _tween_pip(index: int, target: float) -> void:
	var start: float = _pip_alphas[index]
	var tween := create_tween()
	tween.tween_method(func(v: float) -> void:
		if index < _pip_alphas.size():
			_pip_alphas[index] = v
			queue_redraw()
	, start, target, fade_in_duration)

func _draw() -> void:
	if _max_stamina <= 0:
		return
	var total_width: float = float(_max_stamina - 1) * spacing
	var start_x: float = -total_width * 0.5
	for i in _max_stamina:
		var x: float = start_x + float(i) * spacing
		var alpha: float = _pip_alphas[i] if i < _pip_alphas.size() else 0.0

		# Empty slot underlay (dim circle) shows where pips will return to.
		var empty: Color = empty_color
		empty.a *= (1.0 - alpha)
		if empty.a > 0.0:
			draw_circle(Vector2(x, 0), radius, empty)

		# Filled overlay; alpha drives the fade-in.
		if alpha > 0.0:
			var c: Color = filled_color
			c.a *= alpha
			draw_circle(Vector2(x, 0), radius, c)
