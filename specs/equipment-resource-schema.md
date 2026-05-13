# equipment-resource-schema

**Status:** Synced 2026-05-09

## Goal

Define the two equipment Resource classes (`SwordStats`, `AmuletStats`) and migrate the Player to read combat tunables from them. Sword owns damage / cooldown / stamina / gem slots; amulet owns health / dash distance / shields. The roster specs populate `.tres` instances later.

## Player-facing behavior

- No visible change. M3 combat demo plays identically because the two new default `.tres` instances mirror current numbers.
- Going forward, swapping a `.tres` reference on the Player (or via the future `equipment-selection-ui`) changes combat feel without code changes.

## Data

`SwordStats` (`scripts/resources/sword_stats.gd`, `class_name SwordStats`):
- `display_name: String` — shown on selection cards.
- `description: String` — short flavor / mechanical hint on selection cards.
- `base_damage: int` — passed to `take_dash_hit` as the per-slash damage.
- `cooldown_duration: float` — seconds per fire.
- `max_stamina: int` — consecutive-slash cap.
- `stamina_regen_interval: float` — seconds per +1 stamina.
- `gem_slot_count: int` — how many weapon-gem slots (per GDD: usually 2; some 1, some 3).
- `splash_size: float` — placeholder for slash AOE radius; not consumed yet.
- `loaded_tint_color: Color` — modulate applied to player body while loaded.
- `special_ability: Resource` — slot for the future `SwordSpecial` hook resource; null for now.

`AmuletStats` (`scripts/resources/amulet_stats.gd`, `class_name AmuletStats`):
- `display_name: String` — shown on selection cards.
- `description: String` — short flavor / mechanical hint on selection cards.
- `max_health: int` — player template HP; runtime tracks current separately.
- `health_regen_rate: float` — HP per second; not consumed yet.
- `shield_count: int` — discrete hit-absorbers; not consumed yet.
- `shield_regen_interval: float` — seconds per +1 shield; not consumed yet.
- `dash_distance: float` — base pixel distance per dash before modifiers.
- `amulet_effect: Resource` — slot for the future `AmuletEffect` hook resource; null for now.

Player integration (`scripts/player.gd`):
- `@export var equipped_sword: SwordStats` — defaults to `Player.DEFAULT_SWORD_PATH` (`res://resources/equipment/swords/letter_opener.tres`) when null.
- `@export var equipped_amulet: AmuletStats` — defaults to `Player.DEFAULT_AMULET_PATH` (`res://resources/equipment/amulets/id_lanyard.tres`) when null.
- Equipment ladder in `_ready` (highest priority first): `RunState.chosen_sword` / `chosen_amulet` → scene-level export → default path → class default. Selection scene always wins so run-start picks take effect; exports remain useful for direct-scene debugging.
- All `weapon_tuning.*` reads replaced with `equipped_sword.*`.
- Former `@export var max_health` removed; `health` initializes from `equipped_amulet.max_health`.
- `dash_tuning.base_dash_distance` reads replaced with `equipped_amulet.dash_distance` in `_compute_effective` for distance.
- `_apply_loaded_modulate` reads `equipped_sword.loaded_tint_color`.

Resources:
- `resources/equipment/swords/letter_opener.tres` — the default sword (see `sword-roster`); mirrors prior `weapon_tuning.tres` numbers.
- `resources/equipment/amulets/id_lanyard.tres` — the default amulet (see `amulet-roster`); HP 5, dash_distance 80.
- The original `default_sword.tres` / `default_amulet.tres` placeholders are gone; their content lives in the roster files above.

Deprecated, removed by this spec:
- `WeaponTuning` class + `resources/weapon_tuning.tres` — fully replaced by `SwordStats`.
- `DashTuning.base_dash_distance` field — replaced by `AmuletStats.dash_distance`. The rest of `DashTuning` (duration, curve, trail, etc.) stays.

## Edge cases & out-of-scope

- Either equipped_* slot null at `_ready`: fall back by loading the default `.tres`; if that also fails, instantiate `SwordStats.new()` / `AmuletStats.new()` with class defaults and push_warning.
- Tuning swap at runtime: not in scope; equipment-selection-ui handles run-start picks. Mid-run swap is a future concern.
- Modifier system on sword stats (gem-driven damage / cooldown bumps): the existing `core_dash` modifier registries cover dash distance/duration; sword stats grow their own when gems land in later specs.
- Out of scope: sword roster content (separate spec), amulet roster content (separate spec), equipment-selection-ui, gem slot wiring, special-ability hook system, shield mechanic implementation, health-regen mechanic implementation, splash-radius implementation.

## Tasks

- [x] Create `SwordStats` Resource (`scripts/resources/sword_stats.gd`) with the field list above.
- [x] Create `AmuletStats` Resource (`scripts/resources/amulet_stats.gd`) with the field list above.
- [x] Create `resources/equipment/default_sword.tres` and `resources/equipment/default_amulet.tres` with values matching current behavior.
- [x] Migrate `scripts/player.gd`: add `equipped_sword` / `equipped_amulet` `@exports`; load defaults in `_ready` if null; replace `weapon_tuning.*`, `max_health`, and `dash_tuning.base_dash_distance` reads with the new resource fields.
- [x] Update `scenes/player.tscn`: reference the two new default `.tres` files; remove the `weapon_tuning` ext_resource.
- [x] Remove `scripts/resources/weapon_tuning.gd` + `resources/weapon_tuning.tres`. Remove `base_dash_distance` from `scripts/resources/dash_tuning.gd` + `resources/dash_tuning.tres`. Both create drift on prior specs (`weapon-cooldown-stamina`, `core_dash`) — capture at next /sync.
- [x] Smoke-test in `m3_combat_demo`: combat numbers unchanged — same dash distance, same cooldown, same stamina-of-1, same loaded tint, same player HP, same death-after-5-hits.
