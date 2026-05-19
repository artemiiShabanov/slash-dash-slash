extends Node2D

## Health pips.
##
## A row of N small heart-pips above a parent that emits
## `health_changed(current: int, max: int)`. Drained pips disappear
## immediately on damage; restored pips fade back in over `pip_fade_duration`.
##
## Top-level so the row tracks the parent's position but ignores its rotation
## — pips always read horizontally regardless of how the player is facing.

const TUNING_PATH := "res://resources/hud_tuning.tres"
const HEART_RADIUS: float = 2.0

@export var tuning: HudTuning

var _pip_alphas: Array[float] = []
var _max_health: int = 0
var _current_health: int = 0
var _follow_target: Node2D = null
var _base_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	top_level = true
	if tuning == null:
		tuning = load(TUNING_PATH) as HudTuning
		if tuning == null:
			push_warning("HealthPips: failed to load HudTuning; using defaults.")
			tuning = HudTuning.new()
	# Anchor above the stamina pips: stack our row at stamina offset + our delta.
	# StaminaPips uses `Vector2(0, -16)` by default — we sit health_offset above.
	_base_offset = Vector2(0, -16) + tuning.health_offset
	_follow_target = get_parent() as Node2D
	if _follow_target != null and _follow_target.has_signal("health_changed"):
		_follow_target.health_changed.connect(_on_health_changed)

func _process(_delta: float) -> void:
	if _follow_target != null:
		global_position = _follow_target.global_position + _base_offset

func _on_health_changed(current: int, maximum: int) -> void:
	if maximum != _max_health:
		_max_health = maximum
		_pip_alphas.resize(_max_health)
		for i in _max_health:
			_pip_alphas[i] = 1.0 if i < current else 0.0
	for i in _max_health:
		var should_fill: bool = i < current
		var was_filled: bool = i < _current_health
		if should_fill and not was_filled:
			_tween_pip(i, 1.0)
		elif not should_fill and was_filled:
			_pip_alphas[i] = 0.0
	_current_health = current
	queue_redraw()

func _tween_pip(index: int, target: float) -> void:
	var start: float = _pip_alphas[index]
	var tween := create_tween()
	tween.tween_method(func(v: float) -> void:
		if index < _pip_alphas.size():
			_pip_alphas[index] = v
			queue_redraw()
	, start, target, tuning.pip_fade_duration)

func _draw() -> void:
	if _max_health <= 0:
		return
	var total_width: float = float(_max_health - 1) * tuning.pip_spacing
	var start_x: float = -total_width * 0.5
	for i in _max_health:
		var x: float = start_x + float(i) * tuning.pip_spacing
		var alpha: float = _pip_alphas[i] if i < _pip_alphas.size() else 0.0
		var drained: Color = tuning.heart_drained_color
		drained.a *= (1.0 - alpha)
		if drained.a > 0.0:
			draw_circle(Vector2(x, 0), HEART_RADIUS, drained)
		if alpha > 0.0:
			var c: Color = tuning.heart_filled_color
			c.a *= alpha
			draw_circle(Vector2(x, 0), HEART_RADIUS, c)
