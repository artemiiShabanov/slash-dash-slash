extends Node

## CRTOverlay autoload.
##
## Mounts a topmost CanvasLayer with a full-screen ColorRect that runs the CRT
## post-process shader (curvature, scanlines, chromatic aberration, phosphor
## tint, vignette, signal noise). Loads CRTTuning and pushes values to the
## shader. Survives scene changes — the overlay is on by default everywhere.
##
## The ColorRect has MOUSE_FILTER_IGNORE; it does not intercept input.

const TUNING_PATH := "res://resources/crt_tuning.tres"
const SHADER_PATH := "res://assets/shaders/crt_post_process.gdshader"

# Layer index well above any per-scene CanvasLayer; ensures CRT pass is on top.
const OVERLAY_LAYER := 1000

var tuning: CRTTuning
var canvas_layer: CanvasLayer
var rect: ColorRect

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	tuning = load(TUNING_PATH) as CRTTuning
	if tuning == null:
		push_error("CRTOverlay: failed to load tuning at %s; using defaults." % TUNING_PATH)
		tuning = CRTTuning.new()

	canvas_layer = CanvasLayer.new()
	canvas_layer.layer = OVERLAY_LAYER
	add_child(canvas_layer)

	rect = ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.color = Color(1, 1, 1, 1)  # placeholder; the shader does the work

	var shader: Shader = load(SHADER_PATH) as Shader
	if shader == null:
		push_error("CRTOverlay: failed to load shader at %s." % SHADER_PATH)
	else:
		var mat := ShaderMaterial.new()
		mat.shader = shader
		rect.material = mat

	canvas_layer.add_child(rect)
	_apply_tuning()

## Reapply tuning values to the shader. Call this after mutating `tuning`
## (e.g., per-floor variation in a future spec).
func apply_tuning() -> void:
	_apply_tuning()

func _apply_tuning() -> void:
	if rect == null or rect.material == null:
		return
	var mat := rect.material as ShaderMaterial
	mat.set_shader_parameter("tint_color", tuning.tint_color)
	mat.set_shader_parameter("curvature", tuning.curvature)
	mat.set_shader_parameter("scanline_intensity", tuning.scanline_intensity)
	mat.set_shader_parameter("chromatic_aberration", tuning.chromatic_aberration)
	mat.set_shader_parameter("vignette_intensity", tuning.vignette_intensity)
	mat.set_shader_parameter("noise_intensity", tuning.noise_intensity)
	mat.set_shader_parameter("noise_animated", tuning.noise_animated)
