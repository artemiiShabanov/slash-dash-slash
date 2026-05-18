# amulet-gem-roster

**Status:** Shipped

## Goal

Ship three amulet-gem `.tres` instances (vampiric, wall-pass, thorns) with their concrete behaviors and the player-side hook wiring that fires them. Validates every `AmuletGem` hook surface and gives the amulet slot something to put in.

## Player-facing behavior

- Three named amulet gems exist under `resources/gems/amulets/`. Each is a structurally unique mechanic; one subclass per gem.
- **Vampiric** (*Water Cooler Token*) — every slash kill restores `heal_per_kill` HP to the player, capped at the amulet's `max_health`.
- **Wall-pass** (*Janitor's Master Key*) — dashes phase through walls; `wall_hit` never fires while equipped. Reposition + slash dashes both pass.
- **Thorns** (*Stapler Pin Bracelet*) — every time the player takes damage, the source enemy takes `thorns_damage` back instantly. No range check; the attacker that triggered `damaged` is the target.
- Player.tscn equips *Water Cooler Token* as a debug fallback so direct-scene runs demo the on_kill hook. RunState selection (when present) wins.

## Data

`AmuletGem` hook wiring drift (on `gem-resource-schema`) — previously deferred to "when amulet-gem-roster lands"; landing now:
- `Player._ready` calls `equipped_amulet_gem.on_equip(self)` once after equipment resolves; pairs with an `on_unequip` call in a future hot-swap path (no consumer yet — left as the future contract).
- `Player._physics_process(delta)` calls `equipped_amulet_gem.on_tick(self, delta)` if non-null.
- `Player.take_damage(amount, source)` (signature drift, see below) emits `damaged(amount, source)` then calls `equipped_amulet_gem.on_player_damaged(self, amount, source)`.
- `Player._try_hit` calls `equipped_amulet_gem.on_kill(self, enemy_root)` when the contact dropped the target (kill detected from the new `take_dash_hit` return field).

`AmuletGem.on_player_damaged` signature drift (on `gem-resource-schema`):
- Was `(player, amount)`; now `(player, amount, source)` so thorns has an attacker reference. Default no-op body unchanged.

`Player.damaged` signal drift (on `basic-enemy-ai`):
- Was `damaged(amount: int)`; now `damaged(amount: int, source: Node)`. Source is the attacking enemy node, or `null` for damage with no node source (none today).
- `Player.take_damage` gains a `source: Node = null` parameter; `DummyEnemy._do_attack` passes `self`.

`take_dash_hit` return drift (on `hit_detection` + `armor_direction`):
- Returns `{"final_damage": int, "is_back_hit": bool, "killed": bool}`. `killed` is true iff this contact dropped the enemy. Lets `Player._try_hit` call `on_kill` without inspecting the freed node.

Roster files (new), each `extends AmuletGem`:
- `scripts/gems/amulets/vampiric_amulet_gem.gd` (`class_name VampiricAmuletGem`) — `@export var heal_per_kill: int = 1`; overrides `on_kill`: `player.health = mini(player.equipped_amulet.max_health, player.health + heal_per_kill)`, emits `player.damaged(-heal_per_kill, null)` so HUD reacts (or use a dedicated `healed` signal — see edges).
- `scripts/gems/amulets/wall_pass_amulet_gem.gd` (`class_name WallPassAmuletGem`) — no exports. Overrides `on_equip`: store player's prior `collision_mask`, set `collision_mask = 0`. Overrides `on_unequip`: restore.
- `scripts/gems/amulets/thorns_amulet_gem.gd` (`class_name ThornsAmuletGem`) — `@export var thorns_damage: int = 1`. Overrides `on_player_damaged`: if `source != null and source.has_method("take_dash_hit")`, call `source.take_dash_hit(thorns_damage, Vector2.ZERO)` (zero direction → front hit, full armor applies; acceptable for v1).

Resource files (new):
- `resources/gems/amulets/water_cooler_token.tres` — Vampiric, `heal_per_kill = 1`, `display_name = "Water Cooler Token"`, `description = "Sip from every fallen request. Closing a ticket tops you up."`
- `resources/gems/amulets/janitors_master_key.tres` — Wall-pass, `display_name = "Janitor's Master Key"`, `description = "Every door opens. Walls are a suggestion."`
- `resources/gems/amulets/stapler_pin_bracelet.tres` — Thorns, `thorns_damage = 1`, `display_name = "Stapler Pin Bracelet"`, `description = "Sharp on contact. Hit me; bleed."`

## Edge cases & out-of-scope

- Vampiric heal popup: there's no `healed` signal today. Emitting `damaged(-heal_per_kill, null)` is the placeholder hook; the debug `damage_number_spawner` reads negative `damaged` amounts and renders them as green popups at the player. Cleaner path is a follow-up `healed` signal — left noted, not blocking.
- Wall-pass + sword loading: dashes still consume stamina + reload weapon normally; only collision changes. Reposition dashes phase too.
- Wall-pass restoration: if no hot-swap path runs (current code), `on_unequip` is dead code. Acceptable until selection UI gains a swap mid-run.
- Thorns reflecting off armor: zero `dash_direction` makes the dummy compute a front hit (full front armor); on a 0.9 armor enemy, 1 damage thorns rounds to 0. Accepted; tune armor or `thorns_damage` per encounter.
- Thorns when source is null (no enemy passed): on_player_damaged no-ops. Future damage sources (traps, DoTs) must opt in.
- Burn ticks killing an enemy don't trigger `on_kill` (no slash context). Acceptable for v1 — vampiric only rewards explicit kills.
- Multi-kill in one slash (a slash hits N and kills all): `on_kill` fires N times → heals N. Intentional.
- Wall-pass + walls that are death triggers (none today): out of scope until a hazard spec lands.
- Out of scope: amulet-gem upgrade state, unlock conditions (`amulet-unlock-conditions` M22), `healed` signal + HUD wiring, in-run hot-swap UI, amulet gem icons, gem combinations with weapon gems, save/load.

## Tasks

- [x] Update `AmuletGem.on_player_damaged` signature to `(player, amount, source)`; keep default no-op.
- [x] Update `Player.damaged` signal to `(amount: int, source: Node)`; `Player.take_damage` gains `source: Node = null`.
- [x] Update `DummyEnemy._do_attack` to pass `self` as source.
- [x] Extend `take_dash_hit` (`DummyEnemy`) to return `killed: bool` alongside the existing keys.
- [x] Wire AmuletGem hooks on Player: `on_equip` in `_ready`, `on_tick` in `_physics_process`, `on_player_damaged` in `take_damage`, `on_kill` in `_try_hit` (gated on the new `killed` return field).
- [x] Create `scripts/gems/amulets/vampiric_amulet_gem.gd` + `resources/gems/amulets/water_cooler_token.tres`.
- [x] Create `scripts/gems/amulets/wall_pass_amulet_gem.gd` + `resources/gems/amulets/janitors_master_key.tres`.
- [x] Create `scripts/gems/amulets/thorns_amulet_gem.gd` + `resources/gems/amulets/stapler_pin_bracelet.tres`.
- [x] Update `scenes/player.tscn`: set `equipped_amulet_gem` to the Vampiric instance for direct-scene smoke tests.
- [x] Smoke-test in `m3_combat_demo`: with Vampiric equipped, kill a dummy at low HP → player heals (verify via damage flash on next hit or HP popup count). Swap to Wall-pass → dash terminates only against the arena edge, not interior walls. Swap to Thorns → take damage from a dummy → it loses HP, visible via floating damage numbers spawner.
