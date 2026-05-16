# gem-resource-schema

**Status:** Synced 2026-05-16

## Goal

Define `WeaponGem` and `AmuletGem` Resource base classes plus the shared `Element` enum, and wire equipped-gem storage onto `RunState`. Mirrors the composable-hooks pattern from `enemy-ability-base`. Concrete elemental gems + crit-proc mechanic land in their own specs.

## Player-facing behavior

- No visible gameplay change yet — schema only. A placeholder `LogWeaponGem` prints to the console on every slash so the dispatcher wiring is verifiable.
- A sword's `gem_slot_count` continues to declare capacity; this spec adds the *contents* of those slots as `RunState` state.

## Data

`Element` (`scripts/gems/element.gd`, `class_name Element`) — the source of per-element identity, base tunables, and display labels:
```
enum Kind { FIRE, WATER, ICE, WIND, METAL, LIGHTNING }
static func display_name(kind: Kind) -> String       # "Fire", "Water", …
static func base_chance(kind: Kind) -> float         # element-specific proc probability
static func base_damage_multiplier(kind: Kind) -> float
static func color(kind: Kind) -> Color               # added by weapon-gem-crit-proc
```
Shared by `WeaponGem`, per-element SFX, combo content, and future visuals. Tunable element values live here, not on individual gems.

`WeaponGem` (`scripts/gems/weapon_gem.gd`, `class_name WeaponGem`) — concrete Resource. A gem is just a pointer at an element; all base numbers come from `Element.*` lookups. Upgrade state lives elsewhere (added by `upgrade-card-draft` in M15).
- `element: Element.Kind` — drives combos, per-element SFX, per-element special dispatch. UI label resolved via `Element.display_name(element)`. Base proc chance + multiplier resolved via `Element.base_chance(element)` / `Element.base_damage_multiplier(element)`.
- Hooks (defaults: no-ops except `on_proc` which applies the per-element multiplier; per-element specials added in `weapon-gem-roster` as a `match self.element` inside these methods, not via subclassing):
  - `on_slash(player: Node, target: Node, dash_direction: Vector2) -> void` — every contact on a slash dash.
  - `on_proc(player: Node, ctx: SlashContext) -> void` — fires once per slash when this gem is the only one to proc (see `weapon-gem-crit-proc`). Default body: `ctx.damage_multiplier *= Element.base_damage_multiplier(element)` + element tag.
  - `on_kill(player: Node, target: Node) -> void` — slash dropped the target.
  - `on_combo(player: Node, partner_gems: Array, ctx: SlashContext) -> void` — 2+ gems proc'd this slash; fires once per slash on each procced gem, suppresses `on_proc`. Default body: no-op.

No subclasses per element — 6 `.tres` instances differ only in their `element` field. `LogWeaponGem` is the lone subclass (debug-only, not a "seventh element").

`AmuletGem` (`scripts/gems/amulet_gem.gd`, `class_name AmuletGem`) — abstract Resource:
- `display_name: String`, `description: String`.
- Virtual hooks (no-op defaults):
  - `on_equip(player: Node) -> void` — install passive modifiers (e.g., `player.set_dash_distance_modifier("amulet_gem", …)`).
  - `on_unequip(player: Node) -> void` — clear them.
  - `on_player_damaged(player: Node, amount: int) -> void` — reactive (vampiric, retaliation).
  - `on_kill(player: Node, target: Node) -> void` — reactive.
  - `on_tick(player: Node, delta: float) -> void` — continuous (auras).

`RunState` (drift on `equipment-selection-ui`):
- `equipped_weapon_gems: Array[WeaponGem]` — default `[]`; size bounded by `equipped_sword.gem_slot_count` (caller enforces).
- `equipped_amulet_gem: AmuletGem` — default `null`.
- `reset()` clears both alongside the existing chosen_* fields.

Player (`scripts/player.gd`):
- `@export var equipped_weapon_gems: Array[WeaponGem] = []` — debug fallback used when RunState's is empty (mirrors `equipped_sword` ladder).
- `@export var equipped_amulet_gem: AmuletGem` — debug fallback.
- `_ready`: prefer `RunState.equipped_weapon_gems` if non-empty, else export, else `[]`.
- `_ready` connects `hit_landed` to a `_dispatch_gems_on_slash` handler that iterates `equipped_weapon_gems` and calls `on_slash(self, target, dash_direction)` for each non-null gem. The crit/proc/combo flow lands in `weapon-gem-crit-proc`.

`LogWeaponGem` (`scripts/gems/log_weapon_gem.gd`, `class_name LogWeaponGem`) — concrete subclass, prints tagged message (including the resolved element name) on each hook. Element defaults to `FIRE` arbitrarily.
`resources/gems/log_weapon_gem.tres` — single instance for smoke test.

## Edge cases & out-of-scope

- More gems equipped than `gem_slot_count` permits: this spec doesn't enforce the cap; upgrade-card-draft (M15) will guard at insertion time.
- Null entry inside `equipped_weapon_gems`: dispatcher skips, no warning.
- Player runs without going through selection: RunState's gem fields stay at defaults; player exports take over.
- Crit-roll math, combo detection, mega-combo (3+) effect: `weapon-gem-crit-proc` (rolls, single-proc / combo dispatch, `SlashContext`) and `gem-combo-content` (element-pair content) own these.
- Amulet gem dispatcher wiring (on_equip / on_tick / etc.): defined here, fired when `amulet-gem-roster` lands.
- Out of scope: per-element SFX, gem upgrade math, save/load, gem icons, UI to view equipped gems.

## Tasks

- [x] Create `scripts/gems/element.gd` with `class_name Element`, `enum Kind { FIRE, WATER, ICE, WIND, METAL, LIGHTNING }`, and `static` helpers: `display_name(kind)`, `base_chance(kind)`, `base_damage_multiplier(kind)`. Placeholder per-element values within the chance/multiplier ranges; tunable.
- [x] Create `scripts/gems/weapon_gem.gd` (`class_name WeaponGem extends Resource`) with `element: int` (Element.Kind) + four hook methods (empty bodies). No per-gem numeric fields — bases come from `Element.*`.
- [x] Create `scripts/gems/amulet_gem.gd` (`class_name AmuletGem extends Resource`) with the field list + five virtual hooks (empty bodies).
- [x] Create `scripts/gems/log_weapon_gem.gd` (`class_name LogWeaponGem extends WeaponGem`) overriding all four hooks with `print` calls.
- [x] Create `resources/gems/log_weapon_gem.tres` (single instance).
- [x] Extend `RunState` (`scripts/run_state.gd`): add `equipped_weapon_gems: Array[WeaponGem]` and `equipped_amulet_gem: AmuletGem`; clear both in `reset()`.
- [x] Extend `Player`: `@export` fallbacks, _ready resolves RunState→export ladder, connect `hit_landed` to a `_dispatch_gems_on_slash` helper that iterates and calls `on_slash`.
- [x] Smoke-test: log_weapon_gem.tres assigned to player.tscn's `equipped_weapon_gems` array. Run the project, pick equipment, slash a dummy — console shows `[LogWeaponGem:Fire] on_slash target=DummyX dir=(...)` on every contact during slash dashes.
