# sword-roster

**Status:** Synced 2026-05-09

## Goal

Ship two distinct sword `.tres` instances so the run-start choice is a real one. The schema is already defined (`equipment-resource-schema`); this spec only adds content + display metadata.

## Player-facing behavior

- Two named swords exist as `.tres` files under `resources/equipment/swords/`. Each has a `display_name` and `description` so the future `equipment-selection-ui` can label cards.
- The current default `letter_opener.tres` (renamed from `default_sword.tres`) plays exactly like before — same numbers, just with a name and flavor text added.
- The second sword `executive_katana.tres` is a contrasting heavy-hit profile: doubles base damage, halves stamina, slower cooldown, fewer gem slots, small splash, different loaded tint.
- Until `equipment-selection-ui` ships, the player loads `letter_opener.tres` as the default; swap manually in `player.tscn` or via tres edit to try the katana.

## Data

Drift on `equipment-resource-schema` (capture next /sync):
- `SwordStats` gains `display_name: String` and `description: String` (both default `""`).

Roster files (new):
- `resources/equipment/swords/letter_opener.tres` — *Mailroom Letter Opener*. Fast, single-digit damage, 2 gem slots. Stats mirror the prior `default_sword.tres`. Description: short flavor line tying it to the office-tools fiction.
- `resources/equipment/swords/executive_katana.tres` — *Executive Katana*. Heavy single-hit, 1 gem slot, small splash. Loaded tint differs (blood_red) so the swap is visible.

Path move:
- `resources/equipment/default_sword.tres` → relocated content into `swords/letter_opener.tres` and deleted.
- Update `Player.DEFAULT_SWORD_PATH` constant and `scenes/player.tscn` ext_resource ref accordingly.

## Edge cases & out-of-scope

- Player.tscn references the relocated path: the rename is part of this spec's tasks.
- Equipment selection UI: separate spec.
- Sword unlock conditions / achievements: separate `sword-unlock-conditions` spec (M22).
- Special abilities: each sword's `special_ability` slot stays null — wire when `SwordSpecial` hook framework lands.
- Splash AOE on the Executive Katana's `splash_size = 6.0` is a tunable placeholder; no consumer reads it yet.
- Out of scope: amulet roster (next spec), gem slots beyond a count, sword UI cards, achievement-driven unlocks, save-state tracking of which swords have been unlocked.

## Tasks

- [x] Add `display_name: String` and `description: String` to `scripts/resources/sword_stats.gd` with empty defaults.
- [x] Create `resources/equipment/swords/letter_opener.tres` — mirrors current default sword stats; `display_name = "Mailroom Letter Opener"`; descriptive flavor text.
- [x] Create `resources/equipment/swords/executive_katana.tres` — heavy profile: `base_damage = 2`, `cooldown_duration = 0.35`, `max_stamina = 1`, `stamina_regen_interval = 0.7`, `gem_slot_count = 1`, `splash_size = 6.0`, `loaded_tint_color = blood_red`; descriptive flavor text.
- [x] Delete `resources/equipment/default_sword.tres`.
- [x] Update `Player.DEFAULT_SWORD_PATH` constant → `res://resources/equipment/swords/letter_opener.tres`.
- [x] Update `scenes/player.tscn` ext_resource path → `letter_opener.tres`.
- [x] Smoke-test in `m3_combat_demo`: default play feels identical to before (letter opener stats). Manually swap to the katana in `player.tscn` and confirm slower-heavier feel + red loaded tint.
