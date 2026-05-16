extends Node2D
class_name DamageNumber

## Floating damage popup. Spawned at a world position, drifts upward, fades,
## frees itself. Debug-only — used by `damage_number_spawner` to visualize
## per-contact damage in the M3 combat demo.

const LIFETIME: float = 0.7
const RISE_PIXELS: float = 22.0
const HORIZONTAL_JITTER: float = 8.0

@onready var label: Label = $Label

func _ready() -> void:
	var jitter: float = randf_range(-HORIZONTAL_JITTER, HORIZONTAL_JITTER)
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(self, "position", position + Vector2(jitter, -RISE_PIXELS), LIFETIME)
	tween.tween_property(self, "modulate:a", 0.0, LIFETIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(queue_free)

## Configure text, color (e.g. element-tinted), and rough scale. `is_crit`
## bumps font size so procced hits stand out.
func setup(damage: int, color: Color, is_crit: bool) -> void:
	# label may not be ready yet if called before _ready; defer.
	if label == null:
		call_deferred("setup", damage, color, is_crit)
		return
	label.text = str(damage)
	label.modulate = color
	var scale_factor: float = 1.6 if is_crit else 1.0
	scale = Vector2(scale_factor, scale_factor)
