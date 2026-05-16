class_name Element
extends RefCounted

## Element identity for weapon gems. Owns per-kind base values (proc chance,
## crit multiplier, color) and the gem display name + flavor. Gem instances
## just store a `Kind`; everything else flows through static lookups here.
##
## Per-element specials live as `match self.element` arms inside `WeaponGem`'s
## hooks (see `weapon-gem-roster`); this class only holds identity and base
## tunables.

enum Kind {
	FIRE,
	WATER,
	ICE,
	WIND,
	METAL,
	LIGHTNING,
}

## Gem display name (the *item* name, not the bare kind label).
## Used by upgrade cards / inventory UI.
static func display_name(kind: int) -> String:
	match kind:
		Kind.FIRE: return "Ember Memo"
		Kind.WATER: return "Cooler Drop"
		Kind.ICE: return "Freezer Burn"
		Kind.WIND: return "HVAC Whisper"
		Kind.METAL: return "Three-Hole Punch"
		Kind.LIGHTNING: return "Static Cling"
	return "Unknown"

## Short flavor + mechanical hint shown alongside the display name.
static func description(kind: int) -> String:
	match kind:
		Kind.FIRE: return "A coffee-stained dispatch that smolders. Sets enemies alight."
		Kind.WATER: return "Bottled from the water cooler. Fattens the cut and softens the next one."
		Kind.ICE: return "Pried from the breakroom freezer. Slows everything it touches."
		Kind.WIND: return "The vent's complaint, weaponized. Wide cuts, shoved bodies."
		Kind.METAL: return "Bureaucracy as blade. Hits harder than anything else."
		Kind.LIGHTNING: return "Loose office static. Strikes leave enemies twitching, still."
	return ""

## Lowercase, ASCII-friendly tag stem ("fire", "water", …). Used to build
## SlashContext tags like `&"fire_proc"`. Distinct from display_name (which
## is human-facing) so that renaming gems doesn't break tag matching.
static func kind_name(kind: int) -> String:
	match kind:
		Kind.FIRE: return "fire"
		Kind.WATER: return "water"
		Kind.ICE: return "ice"
		Kind.WIND: return "wind"
		Kind.METAL: return "metal"
		Kind.LIGHTNING: return "lightning"
	return "unknown"

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

## Per-element tint used for the proc flash on struck enemies. Placeholder
## palette; tunable. Real visual treatment will graduate to a palette resource
## once `audio_sfx_palette` and a visuals spec mature.
static func color(kind: int) -> Color:
	match kind:
		Kind.FIRE: return Color(1.0, 0.45, 0.15)
		Kind.WATER: return Color(0.30, 0.55, 1.0)
		Kind.ICE: return Color(0.65, 0.90, 1.0)
		Kind.WIND: return Color(0.70, 1.0, 0.60)
		Kind.METAL: return Color(0.85, 0.85, 0.90)
		Kind.LIGHTNING: return Color(1.0, 0.95, 0.30)
	return Color(1, 1, 1)
