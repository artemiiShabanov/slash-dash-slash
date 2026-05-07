class_name HitTuning
extends Resource

## Tunables for the player's hit-through detection. Stored at
## `res://resources/hit_tuning.tres`. `base_damage` is a placeholder until
## sword stats arrive in M5; `hit_radius_offset` adds forgiveness past the
## body's collision radius.

## Damage applied per enemy contact during a slash dash.
@export var base_damage: int = 1

## Pixels added to the player's body radius to compute the HitArea radius.
@export var hit_radius_offset: float = 2.0
