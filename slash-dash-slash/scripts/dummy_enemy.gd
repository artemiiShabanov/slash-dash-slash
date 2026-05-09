extends Area2D
class_name DummyEnemy

## Placeholder enemy for the M3 combat smoke test.
## Replaced by real enemy specs in M4 (will use an EnemyStats resource for
## these fields instead of per-instance @exports).

const FLASH_FRONT: Color = Color(1.3, 1.3, 1.3, 1.0)
const FLASH_BACK: Color = Color(3.0, 3.0, 3.0, 1.0)
const FLASH_FADE_DURATION: float = 0.15

@export var max_health: int = 3

## Direction this enemy is facing. The dash-direction-vs-facing dot product
## decides whether incoming damage applies front_armor or back_armor.
@export var facing: Vector2 = Vector2.RIGHT

## Damage reduction in [0, 1] when hit from the front.
@export_range(0.0, 1.0) var armor_front: float = 0.9

## Damage reduction in [0, 1] when hit from the back.
@export_range(0.0, 1.0) var armor_back: float = 0.0

@onready var visual: Polygon2D = $Visual
@onready var arrow: Polygon2D = $Arrow

var health: int = 0
var _flash_tween: Tween = null

func _ready() -> void:
	add_to_group("enemy")
	health = max_health
	visual.modulate = Color(1, 1, 1, 1)
	# Orient the visible facing arrow.
	if facing.length() > 0.0:
		arrow.rotation = facing.angle()

## Player calls this on contact during a slash dash. Side is decided by the
## sign of the dot product between the dash direction and the enemy's facing.
## Returns the resolved hit info so the player can populate `hit_landed`
## without recomputing the side itself.
func take_dash_hit(damage: int, dash_direction: Vector2) -> Dictionary:
	var is_back_hit: bool = facing.length() > 0.0 and dash_direction.dot(facing) > 0.0
	var armor: float = armor_back if is_back_hit else armor_front
	var final_damage: int = maxi(0, roundi(float(damage) * (1.0 - armor)))
	health -= final_damage
	_flash(FLASH_BACK if is_back_hit else FLASH_FRONT)
	if health <= 0:
		queue_free()
	return {"final_damage": final_damage, "is_back_hit": is_back_hit}

func _flash(color: Color) -> void:
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	visual.modulate = color
	_flash_tween = create_tween()
	_flash_tween.tween_property(visual, "modulate", Color(1, 1, 1, 1), FLASH_FADE_DURATION)
