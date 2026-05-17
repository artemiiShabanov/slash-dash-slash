class_name AmuletGem
extends Resource

## Amulet-slot gem. Unlike weapon gems, amulet gems aren't element
## containers — each one is a unique passive/reactive mechanic per GDD
## (vampiric, wall-pass, etc.), so they keep their own display labels.
## Concrete subclasses override the hooks for their effect.

@export var display_name: String = ""
@export var description: String = ""

# ===== Hooks (override in concrete gems; default no-op) =====

## Run start / equip moment. Install passive modifiers here.
func on_equip(_player: Node) -> void:
	pass

## Gem unequipped or run reset. Mirror-image of on_equip.
func on_unequip(_player: Node) -> void:
	pass

## Player just took damage. React (vampiric, retaliation, etc.). `source`
## is the attacking node (may be null for damage with no node source).
func on_player_damaged(_player: Node, _amount: int, _source: Node) -> void:
	pass

## A slash killed an enemy. React (lifesteal, mana refill).
func on_kill(_player: Node, _target: Node) -> void:
	pass

## Per-physics-frame continuous effects (auras, regen).
func on_tick(_player: Node, _delta: float) -> void:
	pass
