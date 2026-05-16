class_name WeaponGem
extends Resource

## Weapon-slot gem. A gem is a container for an element — all base tunables
## (chance, multiplier, display name, color) come from `Element.*` static
## lookups. Upgrade state will be added by `upgrade-card-draft` (M15).
##
## Per-element specials are dispatched inside the hook methods via
## `match self.element` (no subclasses per element). `LogWeaponGem` is the
## only subclass and is debug-only.

@export var element: int = Element.Kind.FIRE  # Element.Kind value

# ===== Hooks (override in concrete gems; default no-op except on_proc) =====

## Every contact on a slash dash, before proc resolution.
func on_slash(_player: Node, _target: Node, _dash_direction: Vector2) -> void:
	pass

## This gem rolled a crit on the current slash AND it is the only gem to do
## so. Fires once per slash, before any contact. Default body: multiply the
## ctx damage by this element's base multiplier and tag the slash.
func on_proc(_player: Node, ctx: SlashContext) -> void:
	ctx.damage_multiplier *= Element.base_damage_multiplier(element)
	ctx.tags.append(StringName(Element.display_name(element).to_lower() + "_proc"))

## Slash dropped the target to <= 0 HP.
func on_kill(_player: Node, _target: Node) -> void:
	pass

## 2+ gems proc'd on the same slash. Fires once per slash on each participating
## gem with the others as `partner_gems`; suppresses `on_proc`. Default body:
## no-op — combo content is deferred to `gem-combo-content`.
func on_combo(_player: Node, _partner_gems: Array, _ctx: SlashContext) -> void:
	pass
