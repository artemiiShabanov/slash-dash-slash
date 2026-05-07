class_name WeaponTuning
extends Resource

## Tunables for the player's sword cooldown + stamina state machine.
## Stored at `res://resources/weapon_tuning.tres`. Will move onto the equipped
## sword resource once `equipment-resource-schema` lands.

## Seconds from a weapon fire until the cooldown gate clears.
@export var cooldown_duration: float = 0.30

## Maximum consecutive slashes before the player runs out of stamina.
@export var max_stamina: int = 3

## Seconds per +1 stamina point regenerated. Continuous; runs even mid-cooldown.
@export var stamina_regen_interval: float = 0.45

## Modulate color applied to the player Body sprite while the sword is loaded.
## Placeholder until a proper "loaded" sprite animation exists.
@export var loaded_tint_color: Color = Color(0.34, 0.78, 0.42, 1.0)
