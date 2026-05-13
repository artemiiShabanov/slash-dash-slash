class_name PaperStyle
extends RefCounted

## Per-node theme overrides that make a Control read as a paper office memo:
## paper-yellow background, shadow-grey border (ink-black on focus/hover),
## ink-black text, typewriter font.
##
## Lives as overrides (not a theme variation) because Godot's theme editor
## strips manually-authored type-variation entries from `.tres` files on
## save. Overrides survive any theme round-trip.
##
## Usage:
##   PaperStyle.apply_to_button(my_button)
##   PaperStyle.apply_to_rich_text(my_label)
##   PaperStyle.apply_to_label(my_label)
##   var card = PaperStyle.make_paper_card("Name", "Description")

# Palette mirrors `palette.tres` defaults; tune both together if the look shifts.
const BG: Color = Color(0.96, 0.91, 0.74, 1.0)            # paper_yellow
const BG_HOVER: Color = Color(0.92, 0.89, 0.81, 1.0)      # bone_white
const BG_PRESSED: Color = Color(0.85, 0.80, 0.65, 1.0)    # darker paper
const BORDER: Color = Color(0.45, 0.42, 0.38, 1.0)        # shadow_grey
const BORDER_FOCUS: Color = Color(0.07, 0.06, 0.05, 1.0)  # ink_black
const TEXT: Color = Color(0.07, 0.06, 0.05, 1.0)          # ink_black
const FONT_PATH: String = "res://assets/fonts/font_document.ttf"

const PADDING_X: float = 8.0
const PADDING_Y: float = 6.0
const BORDER_WIDTH: int = 1
const DEFAULT_CARD_SIZE: Vector2 = Vector2(240, 125)

# Slightly smaller than the project default (16) so a name + a couple of
# wrapped description lines fit comfortably inside a card without clipping.
const FONT_SIZE: int = 13

# Cached so multiple cards share one Font resource instead of reloading.
static var _cached_font: Font = null

## Returns the typewriter Font (Special Elite). Cached after first load.
## May return null if the font file isn't present; callers should handle that.
static func get_font() -> Font:
	if _cached_font == null:
		_cached_font = load(FONT_PATH) as Font
		if _cached_font == null:
			push_warning("PaperStyle: failed to load typewriter font at %s." % FONT_PATH)
	return _cached_font

## Paper background + ink-black text in every button state.
static func apply_to_button(button: Button) -> void:
	button.add_theme_stylebox_override("normal", _make_stylebox(BG, BORDER))
	button.add_theme_stylebox_override("hover", _make_stylebox(BG_HOVER, BORDER_FOCUS))
	button.add_theme_stylebox_override("pressed", _make_stylebox(BG_PRESSED, BORDER_FOCUS))
	button.add_theme_stylebox_override("focus", _make_stylebox(BG_HOVER, BORDER_FOCUS))
	button.add_theme_stylebox_override("disabled", _make_stylebox(BG, BORDER))
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(color_name, TEXT)

## Ink-black text + typewriter font + paper-sized text on a RichTextLabel.
static func apply_to_rich_text(label: RichTextLabel) -> void:
	label.add_theme_color_override("default_color", TEXT)
	label.add_theme_font_size_override("normal_font_size", FONT_SIZE)
	label.add_theme_font_size_override("bold_font_size", FONT_SIZE)
	var font := get_font()
	if font != null:
		label.add_theme_font_override("normal_font", font)
		label.add_theme_font_override("bold_font", font)

## Ink-black text + typewriter font + paper-sized text on a plain Label.
static func apply_to_label(label: Label) -> void:
	label.add_theme_color_override("font_color", TEXT)
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	var font := get_font()
	if font != null:
		label.add_theme_font_override("font", font)

## Build a focusable, clickable paper card: Button wrapping a centered
## RichTextLabel that renders `[b]name[/b]\\n\\ndescription`. Returns the
## Button; the inner label is accessible at `card.get_node("RichTextLabel")`.
static func make_paper_card(name_text: String, desc_text: String, size: Vector2 = DEFAULT_CARD_SIZE) -> Button:
	var card := Button.new()
	card.custom_minimum_size = size
	card.clip_text = false
	# Button's own text empty — the inner RichTextLabel renders content with
	# bold + wrap that Button.text doesn't support.
	card.text = ""
	apply_to_button(card)

	var label := RichTextLabel.new()
	label.name = "RichTextLabel"
	label.bbcode_enabled = true
	label.fit_content = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.offset_left = PADDING_X
	label.offset_top = PADDING_Y
	label.offset_right = -PADDING_X
	label.offset_bottom = -PADDING_Y
	label.text = "[b]%s[/b]\n\n%s" % [name_text, desc_text]
	apply_to_rich_text(label)
	card.add_child(label)
	return card

static func _make_stylebox(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(BORDER_WIDTH)
	sb.content_margin_left = PADDING_X
	sb.content_margin_top = PADDING_Y
	sb.content_margin_right = PADDING_X
	sb.content_margin_bottom = PADDING_Y
	return sb
