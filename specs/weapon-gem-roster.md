# weapon-gem-roster

**Status:** Shipped (combo-stacks revision 2026-05-16)

## Goal

Implement real per-element on_proc effects for the six existing `Element.Kind` values, so every elemental gem feels mechanically distinct — not just a stat reskin. Gems are created on demand from a factory (no per-element `.tres`); flavor metadata lives on `Element`. All tunables live as fields the future upgrade system can multiply/extend.

## Player-facing behavior

- Six elemental gems are reachable by code (`WeaponGem.create(element)`). Display name and flavor description for each element resolve through `Element` static helpers — one source of truth, no per-element files.
- **FIRE** proc: every enemy struck gains a burn — recurring damage ticks for a duration. Burns from successive procs stack as parallel instances (each ticks on its own timer). No slash-size change.
- **WATER** proc: slash hit-radius gains an additive bonus (visibly fatter), and every enemy struck gains a vulnerability buff — incoming damage is multiplied for a duration. Vulnerability stacks multiplicatively across instances. Buff applies AFTER this slash (this slash itself doesn't double-dip).
- **ICE** proc: every enemy struck gains a slow — movement speed scaled down for a duration. Slows from successive procs stack (slow% summed, capped) with parallel timers.
- **WIND** proc: slash hit-radius gains a multiplicative bonus (even fatter than water), and every enemy struck is shoved along the dash direction.
- **METAL** proc: no special body — just the base per-element damage multiplier (highest of the six, per `Element.base_damage_multiplier`).
- **LIGHTNING** proc: every enemy struck gains a stun — total stop (no movement, no attack windup) for a duration. Stuns stack as parallel instances; while any is active the enemy is stunned.
- Player.tscn loadout is wired by a `debug_loadout: Array[int]` of element ints, resolved to gem instances in `_ready` via the factory. The default demo carries all six elements (slot cap unenforced for now — debug loadout). Combos blend colors; combo content is deferred but combo slashes already stack every procced gem's solo effects (per the updated `weapon-gem-crit-proc` rule — combo *adds*, doesn't replace).

## Data

`Element` drift (on `gem-resource-schema`) — flavor strings move here:
- `static func description(kind: Kind) -> String` — short flavor + mechanical hint, used by future upgrade-card / inventory UI. `display_name` already exists.

`WeaponGem` drift (on `gem-resource-schema`):
- `static func create(element: int) -> WeaponGem` — factory; returns a fresh instance with `element` set. Future upgrade specs extend the factory (or the resulting instance) with upgrade state. No per-gem display fields — UI reads `Element.display_name(gem.element)` / `Element.description(gem.element)`.
- `on_proc(player, ctx)` body grows a `match self.element` dispatch after the existing `super()` (multiplier + tag). Per-element arms write to `ctx` for slash-wide effects (WATER, WIND); per-contact effects (FIRE/WATER vuln/ICE/WIND push/LIGHTNING) are applied by `Player._try_hit` reading `ctx.tags`.

`SlashContext` drift (on `weapon-gem-crit-proc`):
- `hit_radius_multiplier: float = 1.0` — multiplicative bump applied after additive extras. Wind sets it; final radius = `(body_radius + hit_radius_offset + ctx.extra_hit_radius) * ctx.hit_radius_multiplier`.

`WeaponGemTuning` drift (on `weapon-gem-crit-proc`) — add the per-element defaults; future upgrade specs mutate or wrap these via gem-upgrade state:
- `fire_burn_duration: float = 3.0`
- `fire_burn_tick_interval: float = 0.5`
- `fire_burn_damage_mult: float = 0.1` — per-tick damage = `equipped_sword.base_damage * fire_burn_damage_mult`.
- `water_radius_bonus: float = 4.0`
- `water_vulnerability_mult: float = 1.25`
- `water_vulnerability_duration: float = 3.0`
- `ice_slow_pct: float = 0.5` — clamped 0..1.
- `ice_slow_duration: float = 2.0`
- `wind_radius_mult: float = 1.5`
- `wind_knockback_distance: float = 24.0`
- `lightning_stun_duration: float = 1.0`

Per-contact tag handling (in `Player._try_hit`, after `take_dash_hit`):
- `&"fire_proc"` → `enemy_root.apply_burn(sword.base_damage * tuning.fire_burn_damage_mult, tuning.fire_burn_tick_interval, tuning.fire_burn_duration)` if method present.
- `&"water_proc"` → `enemy_root.apply_vulnerability(tuning.water_vulnerability_mult, tuning.water_vulnerability_duration)` if method present.
- `&"ice_proc"` → `enemy_root.apply_slow(tuning.ice_slow_pct, tuning.ice_slow_duration)`.
- `&"wind_proc"` → `enemy_root.apply_knockback(_dash_direction, tuning.wind_knockback_distance)`.
- `&"lightning_proc"` → `enemy_root.apply_stun(tuning.lightning_stun_duration)`.

Damage flow inside `take_dash_hit` (drift on `hit_detection` + `armor_direction`):
- Existing armor logic runs first → `armored_damage`.
- New: `final_damage = roundi(armored_damage * _vulnerability_product())` where `_vulnerability_product` is the product of all live `VulnInstance.damage_mult` values.

`DummyEnemy` (`scripts/dummy_enemy.gd`) gains the duck-typed enemy interface methods used above plus their state. All instance arrays are pruned in `_physics_process` as timers reach 0.
- Status state (private fields):
  - `_burns: Array` of `{ damage_per_tick: float, tick_interval: float, time_to_next_tick: float, time_remaining: float }`
  - `_slows: Array` of `{ slow_pct: float, time_remaining: float }`
  - `_stuns: Array` of `{ time_remaining: float }`
  - `_vulns: Array` of `{ damage_mult: float, time_remaining: float }`
- Methods:
  - `apply_burn(damage_per_tick, tick_interval, duration)` — appends a `_burns` entry.
  - `apply_slow(slow_pct, duration)` — appends a `_slows` entry.
  - `apply_stun(duration)` — appends a `_stuns` entry.
  - `apply_vulnerability(damage_mult, duration)` — appends a `_vulns` entry.
  - `apply_knockback(direction, distance)` — one-shot shove (`global_position += direction.normalized() * distance`); not stored.
- Tick (`_physics_process(delta)`):
  - Burns: each entry, `time_to_next_tick -= delta`; while `<= 0`, deal `damage_per_tick` (rounded; if accumulating fractional, store a `_burn_residual: float` on the instance) and reset `time_to_next_tick += tick_interval`. Then `time_remaining -= delta`; prune when ≤ 0. Burn ticks fire `_dispatch_on_hit` so existing hooks (ability dispatchers) still see them; they do **not** emit player `hit_landed` (that signal is dash-scoped). Killing via burn triggers `_dispatch_on_death` + `queue_free` as today.
  - Slows, stuns, vulns: decrement `time_remaining`; prune ≤ 0.
- AI gating:
  - Stunned (any `_stuns` live) → skip chase movement, cancel `_is_winding_up`, freeze `facing` rotation. Cooldown still ticks.
  - Slowed but not stunned → chase speed multiplied by `1.0 - clampf(sum(slow_pct), 0.0, 0.95)`.
- `take_dash_hit` applies vulnerability after armor (formula above) and returns the post-vuln `final_damage`.
- Visual cues: while any burn live, `visual.modulate` tints toward FIRE color; while frozen-by-stun, ICE color; while slowed, a softer blue. Simple priority: stun > burn > slow > white. Restored when all clear.

`Player` (`scripts/player.gd`):
- New `@export var debug_loadout: Array[int] = []` — `Element.Kind` values. In `_ready`, if `RunState.equipped_weapon_gems` is empty and `equipped_weapon_gems` is empty (the editor-set Resource array), each entry is resolved to a fresh gem via `WeaponGem.create(int)`. Lets player.tscn declare a loadout without storing six Resource files.
- `_on_weapon_fired_for_hit` resizes `hit_area_shape`'s CircleShape2D radius after the gem roll: `(body_radius + hit_tuning.hit_radius_offset + ctx.extra_hit_radius) * ctx.hit_radius_multiplier`. `_on_dash_ended_for_hit` restores via `_apply_hit_radius()`.
- `_try_hit` reads `ctx.tags` post-hit and dispatches the apply_* calls listed above (no metal special; armor pierce dropped).
- No lightning chain — lightning is stun-only now.

Per-element flavor strings (filled into `Element.display_name` / `Element.description`):
- **FIRE** — *Ember Memo* — "A coffee-stained dispatch that smolders. Sets enemies alight."
- **WATER** — *Cooler Drop* — "Bottled from the water cooler. Fattens the cut and softens the next one."
- **ICE** — *Freezer Burn* — "Pried from the breakroom freezer. Slows everything it touches."
- **WIND** — *HVAC Whisper* — "The vent's complaint, weaponized. Wide cuts, shoved bodies."
- **METAL** — *Three-Hole Punch* — "Bureaucracy as blade. Hits harder than anything else."
- **LIGHTNING** — *Static Cling* — "Loose office static. Strikes leave enemies twitching, still."

`Element.display_name` returns the *Name* (e.g. "Ember Memo") rather than the bare kind label — the kind label ("Fire") survives only inside debug prints (`[LogWeaponGem:Fire]`-style call sites update to the new strings; LogWeaponGem itself retires this spec anyway).

## Edge cases & out-of-scope

- Combo (2+ procs) now stacks every procced gem's `on_proc` effects on top of `on_combo` (combo adds, doesn't replace — per the revised `weapon-gem-crit-proc`). Per-contact tags accumulate: a FIRE+WATER combo applies both burn and vulnerability per contact. Radius bumps sum (WATER additive); WIND multiplier overwrites rather than multiplies if both fire (acceptable; the latter wins).
- Vulnerability does NOT apply to the slash that procced it (water's on_proc fires before contacts, but the vuln instance is created *during* contact handling, i.e., after `take_dash_hit` already returned — see ordering above). Vulnerability does apply to any further contacts of the same slash on the SAME enemy if it were possible — but `_hit_this_dash` prevents double-tap, so in practice it kicks in next slash. Acceptable.
- Burn killing an enemy outside a slash: standard `queue_free` path; no `hit_landed` (signal is dash-scoped).
- Slow stack > 95%: capped (never reaches 100% — that's stun's job).
- Wind knockback past walls: `global_position +=` bypasses move_and_slide and can clip (placeholder; real enemies will use a knockback impulse via move_and_collide).
- Fractional burn damage (`base * 0.1` with base=2 → 0.2/tick): tracked via `_burn_residual` on the instance so ticks accumulate and eventually deal 1 HP. No silent rounding to zero.
- Metal proc with no extra effect feels "boring" — accepted, METAL is the pure-damage workhorse (multiplier 3.0 is highest of six).
- LogWeaponGem + log_weapon_gem*.tres files: retired this spec — replaced by the factory + `debug_loadout` in player.tscn. Anywhere else that referenced `Element.display_name(kind)` expecting "Fire" / "Water" / etc. now gets the gem display name ("Ember Memo" / "Cooler Drop") — acceptable churn; no UI consumes it yet.
- Smoke-test slot-cap violation: `executive_katana.gem_slot_count = 1` but `debug_loadout` carries 6 elements. Acknowledged by `weapon-gem-crit-proc`; selection UI will enforce later.
- No per-element `.tres` files: a future inventory or upgrade-card spec that needs to *persist* gem state (upgrade levels, etc.) will store gem instances inside RunState, not back into `.tres` on disk. Save/load is its own future spec.
- Out of scope: gem icons, upgrade-card visibility, gem upgrade state (multipliers / duration extenders land in `upgrade-card-draft`), per-element SFX (`audio_sfx_palette` extension), real enemy interface adoption beyond DummyEnemy, status-icon UI above enemies, debug gem-swap menu (separate `debug-loadout-menu` spec).

## Tasks

- [x] `Element`: rewrite `display_name` to return the gem name (*Ember Memo*, …); add `static func description(kind)` with the six flavor strings.
- [x] `WeaponGem`: add `static func create(element: int) -> WeaponGem`; extend `on_proc` with `match self.element`: WATER bumps `ctx.extra_hit_radius`; WIND sets `ctx.hit_radius_multiplier`; FIRE/ICE/LIGHTNING tag only (default body already tags); METAL no-op beyond default.
- [x] Add `hit_radius_multiplier: float = 1.0` to `SlashContext`.
- [x] Extend `WeaponGemTuning` + `resources/weapon_gem_tuning.tres` with the eleven new fields above.
- [x] Player: add `@export var debug_loadout: Array[int]`; resolve to gem instances in `_ready` (after RunState and editor-set Resource array fallbacks).
- [x] Player: compute HitArea radius from `ctx.extra_hit_radius` + `ctx.hit_radius_multiplier` at weapon_fired; restore on dash_ended.
- [x] Player: in `_try_hit` post-hit, branch on `ctx.tags` → apply_burn / apply_vulnerability / apply_slow / apply_knockback / apply_stun.
- [x] DummyEnemy: add `_burns`, `_slows`, `_stuns`, `_vulns` arrays and the five `apply_*` methods.
- [x] DummyEnemy: extend `_physics_process` — tick burn damage (with residual), decrement all timers, prune; gate chase/windup on stun; scale move speed by slow stack.
- [x] DummyEnemy: extend `take_dash_hit` to multiply post-armor damage by vulnerability product before returning.
- [x] DummyEnemy: status-tint `visual.modulate` priority stun > burn > slow > white; restore on clear.
- [x] Retire `LogWeaponGem`: delete `scripts/gems/log_weapon_gem.gd`, `resources/gems/log_weapon_gem.tres`, `resources/gems/log_weapon_gem_water.tres`.
- [x] Swap `scenes/player.tscn`: clear the existing `equipped_weapon_gems` ext_resource refs; set `debug_loadout` to `[FIRE, WATER, ICE, WIND, METAL, LIGHTNING]`.
- [x] Smoke-test in `m3_combat_demo`: dash through dummies and the tank. Across many slashes verify each element visibly behaves — fire ticks tank HP down between slashes; water shows fatter slash + tank takes more on the NEXT slash after a water proc (popups bigger); ice tank chases slower or stops; wind shoves dummies; metal pops the biggest numbers; lightning freezes a dummy in place. Stacking visible by procing the same element repeatedly.
