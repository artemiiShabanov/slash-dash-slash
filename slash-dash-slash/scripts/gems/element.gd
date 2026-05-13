class_name Element
extends RefCounted

## Element identity for weapon gems. Owns per-kind base values (proc chance,
## crit multiplier) and the display name. Gem instances just store a `Kind`;
## everything else flows through static lookups here.
##
## Per-element specials live as `match self.element` arms inside `WeaponGem`'s
## hooks (added by `weapon-gem-roster` in M7); this class only holds identity
## and base tunables.

enum Kind {
	FIRE,
	WATER,
	ICE,
	WIND,
	METAL,
	LIGHTNING,
}

## Human-readable label for selection UI, upgrade cards, debug logs.
static func display_name(kind: int) -> String:
	match kind:
		Kind.FIRE: return "Fire"
		Kind.WATER: return "Water"
		Kind.ICE: return "Ice"
		Kind.WIND: return "Wind"
		Kind.METAL: return "Metal"
		Kind.LIGHTNING: return "Lightning"
	return "Unknown"

## Per-element base proc chance in `[0, 1]`. Tuned roughly to keep total proc
## frequency in a similar range across elements (rare = high mult, common = low).
static func base_chance(kind: int) -> float:
	match kind:
		Kind.FIRE: return 0.20
		Kind.WATER: return 0.30
		Kind.ICE: return 0.15
		Kind.WIND: return 0.25
		Kind.METAL: return 0.10
		Kind.LIGHTNING: return 0.15
	return 0.0

## Per-element base crit multiplier applied to base damage on proc.
static func base_damage_multiplier(kind: int) -> float:
	match kind:
		Kind.FIRE: return 2.5
		Kind.WATER: return 1.5
		Kind.ICE: return 2.5
		Kind.WIND: return 2.0
		Kind.METAL: return 3.0
		Kind.LIGHTNING: return 2.5
	return 1.0
