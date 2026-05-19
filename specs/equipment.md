# equipment

**Status:** Shipped (consolidated 2026-05-19, supersedes `equipment-resource-schema`, `sword-roster`, `amulet-roster`)

## Goal

The two equipment slots the player picks at run start: sword (damage / cooldown / stamina / gem slots) and amulet (HP / dash distance / shields). Defines the Resource schemas and ships the initial roster (2 swords + 2 amulets) so the M5 selection is a real choice. Selection UI lives in `equipment-selection-ui`.

## Player-facing behavior

- Two named swords exist as `.tres` under `resources/equipment/swords/`. Two named amulets under `resources/equipment/amulets/`. Each carries `display_name` + `description` for selection cards.
- The default loadout (Mailroom Letter Opener + ID Lanyard) plays exactly like the M3 baseline — same dash distance, cooldown, stamina, HP.
- Picking the **Executive Katana** swaps to a heavy single-hit profile (slower cooldown, fewer gem slots, splash placeholder, red loaded tint).
- Picking the **Field Manager's Belt** swaps to a defensive trade: higher HP, shorter dash. Survival over reach.
- Swapping is via `RunState` (selection scene) at run start, or by editing player.tscn for direct-scene debugging.

## Data

`SwordStats` (`scripts/resources/sword_stats.gd`, `class_name SwordStats`):
- `display_name: String`, `description: String` — selection card labels.
- `base_damage: int` — passed to `take_dash_hit` as per-slash damage (multiplied by gem proc ctx before reaching the enemy; see `gems`).
- `cooldown_duration: float` — seconds per fire.
- `max_stamina: int` — consecutive-slash cap.
- `stamina_regen_interval: float` — seconds per +1 stamina.
- `gem_slot_count: int` — usually 2; some 1, some 3 per GDD.
- `splash_size: float` — slash AOE radius placeholder (not yet consumed).
- `loaded_tint_color: Color` — modulate applied to player body while loaded.
- `special_ability: Resource` — slot for the future `SwordSpecial` hook; null today.

`AmuletStats` (`scripts/resources/amulet_stats.gd`, `class_name AmuletStats`):
- `display_name: String`, `description: String`.
- `max_health: int` — template HP.
- `health_regen_rate: float` — HP/sec; not yet consumed.
- `shield_count: int`, `shield_regen_interval: float` — discrete hit absorbers; not yet consumed.
- `dash_distance: float` — base pixel distance per dash before modifiers (consumed by `dash`).
- `amulet_effect: Resource` — slot for the future `AmuletEffect` hook; null today.

Player integration (`scripts/player.gd`):
- `@export var equipped_sword: SwordStats`, `@export var equipped_amulet: AmuletStats`.
- `DEFAULT_SWORD_PATH = res://resources/equipment/swords/letter_opener.tres`, `DEFAULT_AMULET_PATH = res://resources/equipment/amulets/id_lanyard.tres`.
- Resolution ladder in `_ready` (highest first): `RunState.chosen_sword` / `chosen_amulet` → scene export → default path → class default with `push_warning`.
- `health` initializes from `equipped_amulet.max_health`. Dash distance reads `equipped_amulet.dash_distance`. Cooldown / stamina / regen / loaded tint read `equipped_sword.*`.

Roster files (shipped):
- `resources/equipment/swords/letter_opener.tres` — *Mailroom Letter Opener*. Fast, single-digit damage, 2 gem slots. The baseline.
- `resources/equipment/swords/executive_katana.tres` — *Executive Katana*. `base_damage = 2`, `cooldown_duration = 0.35`, `max_stamina = 1`, `stamina_regen_interval = 0.7`, `gem_slot_count = 1`, `splash_size = 6.0`, red `loaded_tint_color`. Heavy profile.
- `resources/equipment/amulets/id_lanyard.tres` — *ID Lanyard*. `max_health = 5`, `dash_distance = 80`. Balanced baseline.
- `resources/equipment/amulets/field_managers_belt.tres` — *Field Manager's Belt*. `max_health = 8`, `dash_distance = 55`. Defensive trade.

Deprecated (removed when this spec landed): `WeaponTuning` class + `resources/weapon_tuning.tres` (fully replaced by `SwordStats`); `DashTuning.base_dash_distance` (moved to `AmuletStats.dash_distance`).

## Edge cases & out-of-scope

- Equipped slot null at `_ready`: fall back via the ladder above; class default + warning is the last resort.
- Mid-run equipment swap: out of scope — `RunState` picks are at run start, no hot-swap path today.
- `splash_size`, `health_regen_rate`, `shield_count`, `shield_regen_interval`, `special_ability`, `amulet_effect` are tunable slots reserved for future specs; varying them today is invisible.
- `gem_slot_count` cap unenforced — `gems` smoke tests intentionally exceed it via `debug_loadout`. Selection UI is where enforcement lands.
- Out of scope: selection UI (separate spec), unlock conditions (`sword-unlock-conditions` / `amulet-unlock-conditions`, M22), special-ability hook framework, shield mechanic, health regen mechanic, splash AOE consumer.
