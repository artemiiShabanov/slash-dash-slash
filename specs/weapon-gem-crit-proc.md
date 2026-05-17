# weapon-gem-crit-proc

**Status:** Synced 2026-05-16 (weapon-gem-roster; combo-stacks revision)

## Goal

Make equipped weapon gems actually do something: each slash rolls per-gem proc chances; procced gems mutate a shared slash context (damage, width, tags) that drives the resulting hits, and 2+ procs in one slash fire the combo hook. Gives gems their first taste of teeth without locking in element-specific content.

## Player-facing behavior

- Each slash dash rolls every equipped weapon gem once at fire time. A procced gem amplifies *the entire slash*, not a single contact.
- Every procced gem fires its `on_proc` (default: per-element damage multiplier + tag + per-element ctx writes).
- A multi-gem proc (2+) **additionally** fires `on_combo` on each procced gem — combo content stacks on top of the solo effects rather than replacing them. (Earlier drafts had combos replace solo procs; reverted because the suppression felt punishing once per-element specials existed.)
- Each enemy struck during an affected slash briefly flashes in the gem's element color instead of plain white. Combo flashes blend the colors of all procced gems.
- Slashes that hit nothing still roll — the proc is just "wasted." Reposition dashes (sword unloaded) roll nothing.
- No SFX yet, no per-element specials, no combo content. The hooks fire; what they do beyond damage/flash is a later spec's problem.

## Data

`SlashContext` (`scripts/gems/slash_context.gd`, `class_name SlashContext extends RefCounted`) — built once per slash at `weapon_fired`; mutated by procced gems' `on_proc`; consumed by the player on every contact.
- `damage_multiplier: float` — default 1.0; procced gems multiply in.
- `extra_hit_radius: float` — default 0.0; additive pixels for the HitArea this slash. Wired into HitArea by `weapon-gem-roster`.
- `hit_radius_multiplier: float` — default 1.0; multiplicative bump applied after additive extras. Set by WIND in `weapon-gem-roster`.
- `tags: Array[StringName]` — free-form labels for downstream specs (e.g. `&"fire_proc"`).
- `procced_gems: Array[WeaponGem]` — populated as each gem rolls.
- `flash_color: Color` — element color of the procced gem (or blended mean for combos); `Color(1,1,1)` if no procs.

`Element` drift (on `gem-resource-schema`):
- `static func color(kind: Kind) -> Color` — per-element tint used for the proc flash. Six placeholder colors; tunable.

`WeaponGemTuning` (`scripts/resources/weapon_gem_tuning.gd`, `class_name WeaponGemTuning`) — single `.tres` at `res://resources/weapon_gem_tuning.tres`:
- `proc_flash_duration: float` — seconds the element-color modulate holds before tween-back (default 0.12).
- Per-element tunables (added by `weapon-gem-roster`): `fire_burn_duration` / `fire_burn_tick_interval` / `fire_burn_damage_mult`, `water_radius_bonus` / `water_vulnerability_mult` / `water_vulnerability_duration`, `ice_slow_pct` / `ice_slow_duration`, `wind_radius_mult` / `wind_knockback_distance`, `lightning_stun_duration`.

`WeaponGem` hook signature drift (on `gem-resource-schema`):
- `on_proc(player: Node, ctx: SlashContext) -> void` — replaces the prior `(player, target, dash_direction)` shape. Fires once per slash on **every** procced gem, before any contact. Default body: `ctx.damage_multiplier *= Element.base_damage_multiplier(element)` and `ctx.tags.append(StringName(Element.kind_name(element) + "_proc"))` (since `weapon-gem-roster` — `kind_name` replaced the original `display_name(...).to_lower()` build), plus per-element ctx writes (WATER/WIND adjust radius fields). Per-element per-contact effects (burn, vuln, slow, knockback, stun) are dispatched by `Player._try_hit` reading tags.
- `on_combo(player: Node, partner_gems: Array[WeaponGem], ctx: SlashContext) -> void` — gains `ctx`. Fires once per slash on each procced gem when **2+** gems procced, **in addition to** `on_proc` (not instead). Default body: no-op — combo content is deferred to `gem-combo-content`. Today a 2+ proc slash already stacks every procced gem's solo effects (multipliers compound, radius bumps sum, all tags fire); combo content will land on top of that.
- `on_slash` and `on_kill` unchanged.

`Player` (`scripts/player.gd`) drift:
- `_current_slash_ctx: SlashContext` — built on `weapon_fired`, cleared on `dash_ended`. Null when no slash is in flight.
- `weapon_fired` handler now: builds a fresh `SlashContext`; iterates `equipped_weapon_gems`; for each non-null gem rolls `randf() < Element.base_chance(gem.element)`; on success, appends to `ctx.procced_gems`. **After** the roll loop: call `on_proc(self, ctx)` on every procced gem. If 2+ procced, also call `on_combo(self, partners_excluding_self, ctx)` on each — combo runs *in addition to* on_proc, stacking. Then set `ctx.flash_color` to that one element's color (single) or the mean of all procced element colors (combo).
- `_dispatch_gems_on_slash` (per-contact, from `gem-resource-schema`) keeps calling `on_slash` for every gem; no change there.
- Per-contact damage: `dealt_damage = roundi(equipped_sword.base_damage * _current_slash_ctx.damage_multiplier)` — passed into `target.take_dash_hit(...)`. (Enemy may further multiply by its own vulnerability stacks before returning `final_damage`; see `hit_detection`.)
- HitArea radius at `weapon_fired` (since `weapon-gem-roster`): `(body_radius + hit_tuning.hit_radius_offset + ctx.extra_hit_radius) * ctx.hit_radius_multiplier`. Baseline restored on `dash_ended`.
- After `take_dash_hit` returns and `hit_landed` is emitted, if `ctx.procced_gems` is non-empty, the player tweens `target.modulate` to `ctx.flash_color` for `proc_flash_duration`, then back to `Color(1,1,1)`. Overrides the dummy's white-flash for that contact (the dummy's own tween still runs; element color wins because the player's tween starts last).

## Edge cases & out-of-scope

- Slash hits nothing: roll still happens, hooks still fire, nothing applies. `on_proc` / `on_combo` fire even with zero contacts — gives reactive amulets/visuals a chance to respond.
- 2+ procs with combo content unimplemented: slash stacks all procced gems' solo effects (multipliers compound; e.g. FIRE+METAL = 2.5 × 3.0 = 7.5×). When `gem-combo-content` lands, its per-pair payload adds on top.
- Reposition dash: `weapon_fired` never fires, so no roll, no ctx, no procs.
- Same gem appearing twice in `equipped_weapon_gems`: rolls independently per slot; both can proc and both count toward combo size.
- Null entry in `equipped_weapon_gems`: dispatcher skips (already true from `gem-resource-schema`).
- Damage rounding: integer truncation via `roundi`; multipliers below 1.0 can reduce damage (acceptable — gems shouldn't go below 1.0, but the math doesn't clamp).
- Out of scope: per-element SFX (`audio_sfx_palette`), combo content (`gem-combo-content`), mega-combo (3+) special effect, gem upgrades changing chance/multiplier, screen shake / hit-stop. (Per-element on_proc bodies and `ctx.extra_hit_radius` → HitArea wiring landed in `weapon-gem-roster`.)

## Tasks

- [x] Create `scripts/gems/slash_context.gd` (`class_name SlashContext extends RefCounted`) with the fields above.
- [x] Add `Element.color(kind)` static helper with six placeholder colors; mark tunable.
- [x] Create `scripts/resources/weapon_gem_tuning.gd` + `resources/weapon_gem_tuning.tres` with `proc_flash_duration = 0.12`.
- [x] Update `WeaponGem.on_proc` signature to `(player, ctx)` with the default body (multiplier + tag). Update `on_combo` to take `ctx`. Update `LogWeaponGem` overrides to match the new signatures (still print).
- [x] Player: add `_current_slash_ctx`; on `weapon_fired` build ctx, roll each gem, fire `on_proc` for procced, fire `on_combo` if 2+. Set `flash_color` post-roll. Clear ctx on `dash_ended`.
- [x] Player: in the per-contact path, multiply `equipped_sword.base_damage` by `ctx.damage_multiplier` before `take_dash_hit`. After the call, if any proc occurred, tween `target.modulate` to `ctx.flash_color` for `proc_flash_duration` then back.
- [x] Smoke-test in `m3_combat_demo`: equip two `log_weapon_gem.tres` (different elements) on the player; dash through dummies — console shows roll results per slash; on procced slashes dummies flash in element color; on combo slashes log shows combo hook with both partners; damage visibly higher (raise sword base_damage temporarily if needed to see HP delta).
