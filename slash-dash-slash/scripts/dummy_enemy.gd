extends Area2D
class_name DummyEnemy

## Placeholder enemy for the M3 hit-detection smoke test.
## Replaced by real enemy specs in M4.

@export var max_health: int = 3

@onready var visual: Polygon2D = $Visual

var health: int = 0
var _flash_tween: Tween = null

func _ready() -> void:
	add_to_group("enemy")
	health = max_health
	visual.modulate = Color(1, 1, 1, 1)

## Player calls this on contact during a slash dash. Armor logic will live
## here (per `armor-direction`) but for now we just subtract.
func take_dash_hit(damage: int, _dash_direction: Vector2) -> void:
	health -= damage
	_flash()
	if health <= 0:
		queue_free()

func _flash() -> void:
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	visual.modulate = Color(2.5, 2.5, 2.5, 1)
	_flash_tween = create_tween()
	_flash_tween.tween_property(visual, "modulate", Color(1, 1, 1, 1), 0.15)
