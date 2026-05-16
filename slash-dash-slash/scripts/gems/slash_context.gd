class_name SlashContext
extends RefCounted

## Per-slash gem proc state. Built fresh on `weapon_fired`, mutated by procced
## gems' `on_proc` / `on_combo`, read by the player when applying each contact.
## Cleared on `dash_ended`.

## Damage multiplier applied to `equipped_sword.base_damage` per contact.
var damage_multiplier: float = 1.0

## Extra pixels added to the HitArea radius for width-altering procs.
## Final radius = (body + base_offset + extra) * hit_radius_multiplier.
var extra_hit_radius: float = 0.0

## Multiplicative bump applied to the final HitArea radius after additive
## extras. Wind sets this; others leave it at 1.0.
var hit_radius_multiplier: float = 1.0

## Free-form tags from procced gems; downstream specs (audio, combo content)
## can react to e.g. `&"fire_proc"` or `&"combo"`.
var tags: Array[StringName] = []

## Gems that rolled a successful proc this slash. Populated by the player
## before any `on_proc` / `on_combo` calls.
var procced_gems: Array[WeaponGem] = []

## Modulate color the player applies to each struck enemy. White when no
## proc fired; element color for single-proc; mean of element colors for combo.
var flash_color: Color = Color(1, 1, 1, 1)
