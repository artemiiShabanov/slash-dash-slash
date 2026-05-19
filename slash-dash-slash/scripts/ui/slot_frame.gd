extends Control
class_name SlotFrame

## Reusable terminal-styled icon slot. Renders a 1px border on a dark fill,
## with one of three inner states:
##   - filled (texture present): draws the texture stretched to fit.
##   - filled (fallback): draws a solid color square + the first letter of the
##     entity's display_name in the default theme font. Used while icon assets
##     are placeholders.
##   - empty: border only, inner dimmed by `tuning.slot_empty_alpha`.
##
## Used by `EquipmentChip` for sword / amulet / weapon-gem / amulet-gem slots.

const BG_COLOR: Color = Color(0.05, 0.06, 0.05, 1.0)   # boardroom_black-ish
const LETTER_COLOR: Color = Color(0.05, 0.06, 0.05, 1.0)
const BORDER_THICKNESS: float = 1.0

@export var tuning: HudTuning

var _texture: Texture2D = null
var _fallback_color: Color = Color(1, 1, 1)
var _fallback_letter: String = ""
var _is_empty: bool = true

func _ready() -> void:
	if tuning == null:
		tuning = load("res://resources/hud_tuning.tres") as HudTuning
		if tuning == null:
			tuning = HudTuning.new()
	var size_px: float = float(tuning.icon_size)
	custom_minimum_size = Vector2(size_px, size_px)
	size = custom_minimum_size

## Fill the slot. Pass a texture if available; otherwise pass a fallback
## color + letter and the slot renders a labeled colored square.
func set_filled(texture: Texture2D, fallback_color: Color, fallback_letter: String) -> void:
	_texture = texture
	_fallback_color = fallback_color
	_fallback_letter = fallback_letter.substr(0, 1).to_upper() if fallback_letter.length() > 0 else ""
	_is_empty = false
	queue_redraw()

## Render as an empty slot (border only, dim inner).
func set_empty() -> void:
	_texture = null
	_fallback_letter = ""
	_is_empty = true
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var inner := rect.grow(-BORDER_THICKNESS)
	# Background (always).
	draw_rect(rect, BG_COLOR, true)
	# Inner content.
	if _is_empty:
		# Dim slot indicates capacity exists but no gem fills it.
		var dim: Color = tuning.slot_frame_color
		dim.a *= tuning.slot_empty_alpha
		draw_rect(inner, dim, true)
	elif _texture != null:
		draw_texture_rect(_texture, inner, false)
	else:
		# Fallback: solid color block + centered letter.
		draw_rect(inner, _fallback_color, true)
		if _fallback_letter != "":
			var theme_font: Font = get_theme_default_font()
			var font_size: int = max(8, int(size.y * 0.7))
			var letter_size: Vector2 = theme_font.get_string_size(
				_fallback_letter, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size
			)
			var letter_pos := Vector2(
				size.x * 0.5 - letter_size.x * 0.5,
				size.y * 0.5 + letter_size.y * 0.3,
			)
			draw_string(theme_font, letter_pos, _fallback_letter,
				HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size, LETTER_COLOR)
	# Border (drawn last so it sits over inner fill).
	draw_rect(rect, tuning.slot_frame_color, false, BORDER_THICKNESS)
