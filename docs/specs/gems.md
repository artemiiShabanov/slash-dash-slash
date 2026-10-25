# gems

**Status:** Synced 2026-05-19 (hud; consolidated, supersedes `gem-resource-schema`, `weapon-gem-crit-proc`, `weapon-gem-roster`, `amulet-gem-roster`)

## Goal

One spec for the entire gem system: the two Resource hierarchies (`WeaponGem` + `AmuletGem`), the per-slash proc roll + combo dispatch, the six elemental weapon gems with real per-element effects, the three amulet gems with reactive/passive hooks, and all the player-side wiring that fires them.

## Player-facing behavior

- Weapon gems are slotted into the equipped sword's `gem_slot_count` slots. Each slash dash rolls every equipped gem once at fire time.
- Every procced gem fires `on_proc` (default: per-element damage multiplier + tag + per-element ctx writes). If 2+ proc, each *additionally* fires `on_combo` — combo content stacks on top of solo effects (not replaces).
- The slash flashes each struck enemy in the gem's element color (single proc) or the blended mean of procced colors (combo).
- Per-element effects (post-contact, dispatched by ctx tags):
  - **FIRE** — applies a burn DoT (parallel instance per proc, fractional damage accumulates via residual).
  - **WATER** — additive `extra_hit_radius` bump (fatter slash) + applies a vulnerability buff (multiplies all incoming damage for a duration; stacks multiplicatively post-slash).
  - **ICE** — applies a slow (stacks summed, capped at 95%).
  - **WIND** — multiplicative `hit_radius_multiplier` bump + knockback per contact along dash direction.
  - **METAL** — pure damage workhorse; highest base multiplier, no extra effect.
  - **LIGHTNING** — applies a stun (total stop; movement + windup frozen; stacks parallel).
- A single amulet gem slot. Three concrete gems:
  - **Water Cooler Token** (vampiric) — every slash kill restores HP up to the amulet cap.
  - **Janitor's Master Key** (wall-pass) — dashes phase through walls (player `collision_mask = 0` on equip).
  - **Stapler Pin Bracelet** (thorns) — every hit taken reflects fixed damage back at the attacker.

## Data

`Element` (`scripts/gems/element.gd`, `class_name Element`):
- `enum Kind { FIRE, WATER, ICE, WIND, METAL, LIGHTNING }`.
- `static func display_name(kind: Kind) -> String` — gem item name (*Ember Memo*, *Cooler Drop*, *Freezer Burn*, *HVAC Whisper*, *Three-Hole Punch*, *Static Cling*).
- `static func description(kind: Kind) -> String` — short flavor + mechanical hint.
- `static func kind_name(kind: Kind) -> String` — lowercase tag stem (`"fire"`, …). Distinct from display_name so renaming gems doesn't break tag matching.
- `static func base_chance(kind: Kind) -> float`, `base_damage_multiplier(kind) -> float`, `color(kind) -> Color`.
- `static func icon(kind: Kind) -> Texture2D` (added by `hud`) — loads `assets/icons/elements/<kind_name>.png` if present, else null (HUD falls back to a procedural placeholder).

`WeaponGem` (`scripts/gems/weapon_gem.gd`, `class_name WeaponGem extends Resource`):
- `@export var element: int` — `Element.Kind` value.
- `static func create(kind: int) -> WeaponGem` — factory; replaces per-element `.tres` files.
- Hooks (defaults except `on_proc` are no-op):
  - `on_slash(player, target, dash_direction)` — fires every contact.
  - `on_proc(player, ctx)` — once per slash on every procced gem. Default body: `ctx.damage_multiplier *= Element.base_damage_multiplier(element)`, `ctx.tags.append(StringName(Element.kind_name(element) + "_proc"))`, plus `match self.element` for slash-wide effects: WATER bumps `ctx.extra_hit_radius += tuning.water_radius_bonus`; WIND sets `ctx.hit_radius_multiplier = tuning.wind_radius_mult`; METAL/FIRE/ICE/LIGHTNING tag only (per-contact effects fire in `combat-hit-resolution`'s `_try_hit`).
  - `on_kill(player, target)`.
  - `on_combo(player, partner_gems, ctx)` — once per slash on each procced gem when 2+ procced; in addition to (not instead of) on_proc. Default no-op; combo content deferred to `gem-combo-content`. WIND multiplier last-write-wins if two WIND gems proc.

`AmuletGem` (`scripts/gems/amulet_gem.gd`, `class_name AmuletGem extends Resource`):
- `@export var display_name: String`, `description: String`, `icon: Texture2D` (icon added by `hud`; null falls back to placeholder).
- Hooks (all default no-op):
  - `on_equip(player)` — install passive modifiers. Called from `Player._ready`.
  - `on_unequip(player)` — restore. No call site yet (no hot-swap path).
  - `on_player_damaged(player, amount, source)` — reactive. Called from `Player.take_damage`. `source` is the attacker node (may be null).
  - `on_kill(player, target)` — reactive. Called from `_try_hit` when `take_dash_hit` returns `killed = true`.
  - `on_tick(player, delta)` — continuous. Called from `_physics_process`.

`SlashContext` (`scripts/gems/slash_context.gd`, `class_name SlashContext extends RefCounted`) — built once per slash at `weapon_fired`, mutated by procced gems, read by `_try_hit`, cleared at `dash_ended`:
- `damage_multiplier: float = 1.0` — procced gems multiply in.
- `extra_hit_radius: float = 0.0` — additive HitArea pixels (WATER).
- `hit_radius_multiplier: float = 1.0` — multiplicative bump after additives (WIND).
- `tags: Array[StringName]` — proc tags consumed by per-contact effects.
- `procced_gems: Array[WeaponGem]` — populated by the roll.
- `flash_color: Color` — element color for single proc, mean for combo; `Color(1,1,1)` if no procs.

`WeaponGemTuning` (`scripts/resources/weapon_gem_tuning.gd`) at `res://resources/weapon_gem_tuning.tres`:
- Presentation: `proc_flash_duration` (default 0.12).
- FIRE: `fire_burn_duration` (3.0), `fire_burn_tick_interval` (0.5), `fire_burn_damage_mult` (0.1 — per-tick damage = `equipped_sword.base_damage × this`).
- WATER: `water_radius_bonus` (4.0), `water_vulnerability_mult` (1.25), `water_vulnerability_duration` (3.0).
- ICE: `ice_slow_pct` (0.5; clamped 0..1; stacks sum cap at 0.95), `ice_slow_duration` (2.0).
- WIND: `wind_radius_mult` (1.5), `wind_knockback_distance` (24.0).
- LIGHTNING: `lightning_stun_duration` (1.0).

RunState (extends `equipment-selection-ui`): `equipped_weapon_gems: Array[WeaponGem]` (default `[]`), `equipped_amulet_gem: AmuletGem` (default `null`); both cleared in `reset()`.

Player wiring (`scripts/player.gd`):
- `@export var equipped_weapon_gems: Array[WeaponGem]`, `@export var equipped_amulet_gem: AmuletGem`, `@export var debug_loadout: Array[int]`. Resolution in `_ready`: RunState wins; else editor-set Resource array; else `debug_loadout` resolved via `WeaponGem.create(kind)`.
- After equipment resolves: call `equipped_amulet_gem.on_equip(self)` if non-null.
- `_on_weapon_fired_for_gems`: build fresh `SlashContext`; for each non-null gem `if randf() < Element.base_chance(gem.element): ctx.procced_gems.append(gem)`. Then call `on_proc(self, ctx)` on every procced gem; if 2+, also call `on_combo(self, partners_excluding_self, ctx)` on each. Set `ctx.flash_color` to that element's color (single) or mean of all procced (combo).
- HitArea radius at `weapon_fired`: `(body_radius + hit_tuning.hit_radius_offset + ctx.extra_hit_radius) × ctx.hit_radius_multiplier`. Restored on `dash_ended`.
- `_try_hit` per-contact post-hit, branching on `ctx.tags`: `fire_proc` → `enemy.apply_burn(base × fire_burn_damage_mult, fire_burn_tick_interval, fire_burn_duration)`; `water_proc` → `apply_vulnerability(water_vulnerability_mult, water_vulnerability_duration)`; `ice_proc` → `apply_slow(ice_slow_pct, ice_slow_duration)`; `wind_proc` → `apply_knockback(_dash_direction, wind_knockback_distance)`; `lightning_proc` → `apply_stun(lightning_stun_duration)`. Each guarded by `has_method`.
- Amulet hooks: `on_tick(self, delta)` in `_physics_process`; `on_player_damaged(self, amount, source)` in `take_damage`; `on_kill(self, enemy_root)` in `_try_hit` gated on the `killed` field returned by `take_dash_hit`.
- `Player.damaged` signal is `(amount: int, source: Node)`. `Player.take_damage(amount, source: Node = null)`. `DummyEnemy._do_attack` passes `self` as source.

Amulet gem implementations:
- `VampiricAmuletGem` (`scripts/gems/amulets/vampiric_amulet_gem.gd`) — `@export var heal_per_kill: int`. `on_kill` routes through `player._set_health(player.health + heal_per_kill, null)` (since `hud`). `_set_health` clamps, emits `health_changed` for the HUD, and emits `damaged(prev - new, null)` so the debug `damage_number_spawner` keeps rendering green popups.
- `WallPassAmuletGem` (`scripts/gems/amulets/wall_pass_amulet_gem.gd`) — `on_equip` stores `_prior_mask`, sets `player.collision_mask = 0`. `on_unequip` restores. No-op restore today (no hot-swap call site).
- `ThornsAmuletGem` (`scripts/gems/amulets/thorns_amulet_gem.gd`) — `@export var thorns_damage: int`. `on_player_damaged`: if `source` valid + has `take_dash_hit`, call `source.take_dash_hit(thorns_damage, Vector2.ZERO)` (counts as a front hit, full armor applies).

Tres instances: `resources/gems/amulets/water_cooler_token.tres` (heal_per_kill=1), `janitors_master_key.tres`, `stapler_pin_bracelet.tres` (thorns_damage=1).

LogWeaponGem and per-element weapon-gem `.tres` files were retired during consolidation. Weapon gems are instance-only via the factory.

## Edge cases & out-of-scope

- Slash hits nothing: roll still happens, hooks still fire. `on_proc` / `on_combo` fire even with zero contacts — gives reactive amulets/visuals a chance to respond.
- Reposition dash (sword unloaded): `weapon_fired` never fires, no roll, no procs.
- Same gem appearing twice in `equipped_weapon_gems`: rolls independently per slot; both can proc.
- WIND + WIND combo: `hit_radius_multiplier = wind_radius_mult` is an assignment, not multiply — two WIND procs still yield `1.5×`. Documented; acceptable.
- Vulnerability applies AFTER the procced slash (instance created during `_try_hit` post-hit; next contact on same enemy or next slash benefits).
- Burn killing an enemy outside a slash: no `hit_landed` (signal is dash-scoped); no amulet `on_kill` either (no slash context).
- Fractional burn damage (e.g. base=2 × 0.1 = 0.2/tick): per-instance `residual` accumulates so ticks eventually deal 1 HP rather than rounding silently to zero.
- Slow stack > 95%: capped (never tips into stun's domain).
- Wind knockback past walls: `global_position +=` bypasses move_and_slide; placeholder.
- Multi-kill in one slash: `on_kill` fires N times → vampiric heals N. Intentional.
- Thorns reentrancy: enemy `_do_attack` checks `is_instance_valid(self)` after the player call before mutating cooldown.
- `WallPassAmuletGem.on_unequip` is dead today (no hot-swap path); restoration code reserved.
- Heal popup uses the negative `damaged` delta emitted by `Player._set_health` as a placeholder; the debug damage_number_spawner renders it green. A dedicated `healed` signal is the cleaner future path.
- `equipped_sword.gem_slot_count` cap unenforced — `debug_loadout` exceeds it intentionally for demo. Selection UI is where enforcement lands.
- Out of scope: combo content (per-pair element payloads — `gem-combo-content`), mega-combo (3+ special effect), gem upgrades (chance / multiplier / duration extenders — `upgrade-card-draft`), per-element SFX, gem icons, status-icon UI above enemies, real `healed` signal, debug gem-swap menu (separate `debug-loadout-menu`).
