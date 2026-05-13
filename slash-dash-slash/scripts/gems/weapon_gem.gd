class_name WeaponGem
extends Resource

## Weapon-slot gem. A gem is a container for an element — all base tunables
## (chance, multiplier, display name) come from `Element.*` static lookups.
## Upgrade state will be added by `upgrade-card-draft` (M15).
##
## Per-element specials are dispatched inside the hook methods via
## `match self.element` (no subclasses per element). `LogWeaponGem` is the
## only subclass and is debug-only.

@export var element: int = Element.Kind.FIRE  # Element.Kind value

# ===== Hooks (override in concrete gems; default no-op) =====

## Every contact on a slash dash, before proc resolution.
func on_slash(_player: Node, _target: Node, _dash_direction: Vector2) -> void:
	pass

## This gem rolled a crit on the current slash.
func on_proc(_player: Node, _target: Node, _dash_direction: Vector2) -> void:
	pass

## Slash dropped the target to <= 0 HP.
func on_kill(_player: Node, _target: Node) -> void:
	pass

## Multiple gems proc'd on the same slash; called on each participating gem
## with the others as `partner_gems`.
func on_combo(_player: Node, _partner_gems: Array, _target: Node) -> void:
	pass
