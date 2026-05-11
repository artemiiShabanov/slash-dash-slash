# equipment-resource-schema

**Status:** Shipped

## Goal

Define the two equipment Resource classes (`SwordStats`, `AmuletStats`) and migrate the Player to read combat tunables from them. Sword owns damage / cooldown / stamina / gem slots; amulet owns health / dash distance / shields. The roster specs populate `.tres` instances later.

## Player-facing behavior

- No visible change. M3 combat demo plays identically because the two new default `.tres` instances mirror current numbers.
- Going forward, swapping a `.tres` reference on the Player (or via the future `equipment-selection-ui`) changes combat feel without code changes.

## Data

`SwordStats` (`scripts/resources/sword_stats.gd`, `class_name SwordStats`):
- `base_damage: int` — passed to `take_dash_hit` as the per-slash damage.
- `cooldown_duration: float` — seconds per fire.
- `max_stamina: int` — consecutive-slash cap.
- `stamina_regen_interval: float` — seconds per +1 stamina.
- `gem_slot_count: int` — how many weapon-gem slots (per GDD: usually 2; some 1, some 3).
- `splash_size: float` — placeholder for slash AOE radius; not consumed yet.
- `loaded_tint_color: Color` — modulate applied to player body while loaded.
- `special_ability: Resource` — slot for the future `SwordSpecial` hook resource; null for now.

`AmuletStats` (`scripts/resources/amulet_stats.gd`, `class_name AmuletStats`):
- `max_health: int` — player template HP; runtime tracks current separately.
- `health_regen_rate: float` — HP per second; not consumed yet.
- `shield_count: int` — discrete hit-absorbers; not consumed yet.
- `shield_regen_interval: float` — seconds per +1 shield; not consumed yet.
- `dash_distance: float` — base pixel distance per dash before modifiers.
- `amulet_effect: Resource` — slot for the future `AmuletEffect` hook resource; null for now.

Player integration (`scripts/player.gd`):
- `@export var equipped_sword: SwordStats` — loaded from `res://resources/equipment/default_sword.tres` if null.
- `@export var equipped_amulet: AmuletStats` — loaded from `res://resources/equipment/default_amulet.tres` if null.
- Replace all `weapon_tuning.*` reads with `equipped_sword.*`.
- Replace `max_health` `@export` + reads with `equipped_amulet.max_health`.
- Replace `dash_tuning.base_dash_distance` reads with `equipped_amulet.dash_distance` (used as the base in `_compute_effective` for distance).
- `_apply_loaded_modulate` reads `equipped_sword.loaded_tint_color`.

Resources:
- `resources/equipment/default_sword.tres` — defaults matching current `weapon_tuning.tres` (cooldown 0.2, max_stamina 1, regen 0.45, loaded tint dot_matrix_green) + base_damage 1, gem_slot_count 2, splash_size 0.
- `resources/equipment/default_amulet.tres` — defaults matching current player (max_health 5, dash_distance 80) + zeroed regen/shields/effect.

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
