# amulet-roster

**Status:** Synced 2026-05-09

## Goal

Ship two distinct amulet `.tres` instances so the second half of run-start equipment is a real choice. Mirrors `sword-roster`'s pattern.

## Player-facing behavior

- Two named amulets exist as `.tres` files under `resources/equipment/amulets/`. Each has a `display_name` and `description` so `equipment-selection-ui` can label cards.
- Default `id_lanyard.tres` (renamed from `default_amulet.tres`) plays exactly like before — same HP (5), same dash distance (80).
- Second amulet `field_managers_belt.tres` trades reach for survival: higher HP, shorter dash. Differentiates the choice from pure stat upgrades — a real archetype trade.
- Until `equipment-selection-ui` ships, the player loads `id_lanyard.tres` as the default; swap manually in `player.tscn` to try the belt.

## Data

Drift on `equipment-resource-schema` (capture next /sync, alongside the SwordStats drift):
- `AmuletStats` gains `display_name: String` and `description: String` (both default `""`).

Roster files (new):
- `resources/equipment/amulets/id_lanyard.tres` — *ID Lanyard*. Balanced default; mirrors prior `default_amulet.tres` stats.
- `resources/equipment/amulets/field_managers_belt.tres` — *Field Manager's Belt*. Defensive trade: `max_health = 8`, `dash_distance = 55`. Higher HP, shorter reach.

Path move:
- `resources/equipment/default_amulet.tres` → relocated content into `amulets/id_lanyard.tres` and deleted.
- Update `Player.DEFAULT_AMULET_PATH` constant and `scenes/player.tscn` ext_resource ref accordingly.

## Edge cases & out-of-scope

- Player.tscn references the relocated path: the rename is part of this spec's tasks.
- Equipment selection UI: separate spec.
- Amulet unlock conditions (per GDD, amulets unlock via in-run achievements): separate `amulet-unlock-conditions` spec (M22).
- `amulet_effect` slot stays null — wire when `AmuletEffect` hook framework lands.
- `health_regen_rate`, `shield_count`, `shield_regen_interval` stay at 0 on both amulets — none of those mechanics are consumed yet, so varying them now would be invisible.
- Out of scope: gem slot wiring (amulet gem is one per GDD; defined in `amulet-gem-roster` later), unlock flow, save-state, UI cards.

## Tasks

- [x] Add `display_name: String` and `description: String` to `scripts/resources/amulet_stats.gd` with empty defaults.
- [x] Create `resources/equipment/amulets/id_lanyard.tres` — `max_health = 5`, `dash_distance = 80`, regen/shields all 0; `display_name = "ID Lanyard"`; flavor text.
- [x] Create `resources/equipment/amulets/field_managers_belt.tres` — `max_health = 8`, `dash_distance = 55`, regen/shields all 0; `display_name = "Field Manager's Belt"`; flavor text.
- [x] Delete `resources/equipment/default_amulet.tres`.
- [x] Update `Player.DEFAULT_AMULET_PATH` constant → `res://resources/equipment/amulets/id_lanyard.tres`.
- [x] Update `scenes/player.tscn` ext_resource path → `id_lanyard.tres`.
- [x] Smoke-test in `m3_combat_demo`: default play feels identical (5 HP, 80 dash). Manually swap to the belt in `player.tscn` and confirm 8 HP (survives 8 hits instead of 5) and shorter dash reach.
