class_name SwordStats
extends Resource

## Sword equipment. Owns combat tunables that vary per sword: damage,
## cooldown, stamina, gem-slot count, splash size, loaded-state visual,
## and a special-ability slot. Plus display metadata for selection UI.
##
## One `.tres` per sword archetype. The Player references one as
## `equipped_sword` and reads its fields directly.

## Human-readable name shown in equipment-selection UI cards.
@export var display_name: String = ""

## Short flavor / mechanical hint, shown on selection cards.
@export var description: String = ""

## Base per-slash damage handed to `take_dash_hit`. Single-digit per GDD;
## gems do the real lifting via crits and combos (added in M7+).
@export var base_damage: int = 1

## Seconds between weapon fires.
@export var cooldown_duration: float = 0.2

## Consecutive-slash cap before the player must wait on regen.
@export var max_stamina: int = 1

## Seconds per +1 stamina point. Continuous; runs even mid-cooldown.
@export var stamina_regen_interval: float = 0.45

## How many weapon-gem slots this sword has. Per GDD: typically 2; some 1, some 3.
@export var gem_slot_count: int = 2

## Placeholder for slash AOE radius. Not consumed yet.
@export var splash_size: float = 0.0

## Modulate color applied to the player body while the sword is loaded.
## Placeholder until proper "loaded" sprite animation exists.
@export var loaded_tint_color: Color = Color(0.34, 0.78, 0.42, 1.0)

## Slot for the future `SwordSpecial` hook resource. Null for M5.
@export var special_ability: Resource

## Optional icon for HUD / selection card display. Null falls back to a
## procedural placeholder (palette color + first letter of display_name).
@export var icon: Texture2D
