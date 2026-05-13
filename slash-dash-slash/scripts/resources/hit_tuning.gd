class_name HitTuning
extends Resource

## Tunables for the player's hit-area sizing. Stored at
## `res://resources/hit_tuning.tres`. Per-slash damage comes from
## `equipped_sword.base_damage`, not from here.

## Pixels added to the player's body radius to compute the HitArea radius.
@export var hit_radius_offset: float = 2.0
