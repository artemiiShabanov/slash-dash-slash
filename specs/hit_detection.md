# hit-detection

**Status:** Shipped

## Goal

Make a slashing dash deal damage to every enemy along its path. One slash = one chance to hit each enemy in the line, no double-tap.

## Player-facing behavior

- A slash dash damages every enemy whose body the player passes through, in a single pass.
- A reposition dash (sword unloaded) deals no damage; the hit area is inactive.
- Each enemy takes damage at most once per dash, even if the player crosses them multiple times somehow.
- Enemies show a brief hit reaction (placeholder: white flash) and disappear when their health reaches zero.
- The player emits a `hit_landed` signal on every contact for future systems (gems, juice, sound) to react.

## Data

- Signal: `hit_landed(target: Node, damage: int, position: Vector2, dash_direction: Vector2)` — emitted on the player after each per-enemy contact during a slash dash.
- State on player: `_hit_this_dash: Dictionary` — set of enemies already hit in the current dash; reset on `weapon_fired`.
- Hit area: `HitArea` (Area2D child of the player) with a `CircleShape2D` of radius `body_radius + hit_radius_offset`. `monitoring` is toggled on at `weapon_fired`, off at `dash_ended`. On enable, queries `get_overlapping_areas` (deferred one frame) to catch enemies already inside.
- Tunables — `res://resources/hit_tuning.tres` (`class_name HitTuning`):
  - `base_damage: int` — placeholder per-slash damage until sword stats arrive in M5.
  - `hit_radius_offset: float` — added to body radius for forgiveness margin (default 2.0).
- Enemy interface (duck-typed): `take_dash_hit(damage: int, dash_direction: Vector2) -> void`. Any node with this method participates. Armor logic lives inside the enemy (the `armor-direction` spec extends this).
- Dummy enemy: `scenes/dummy_enemy.tscn` + `scripts/dummy_enemy.gd` — placeholder for M3 smoke test only; replaced by real enemies in M4.
  - Health (default 3), `take_dash_hit` subtracts damage, flashes modulate white briefly, `queue_free` at ≤ 0.
  - Has its own Area2D + CollisionShape2D for the player's HitArea to detect. Mark with group `"enemy"`.

## Edge cases & out-of-scope

- Enemy already overlapping at `weapon_fired`: caught by the deferred `get_overlapping_areas` check on enable.
- Enemy entering the area after dash end: ignored — `monitoring` is off.
- Same enemy entering, leaving, re-entering during one dash: hit once total (per-dash hit list).
- Reposition dash (`is_weapon_loaded` was false): HitArea stays disabled; `weapon_fired` never fires.
- Out of scope: armor calculation (`armor-direction`), per-element crit damage, gem procs, hit feedback beyond a single white flash, real enemy AI, knockback, hit-stop, screen shake, sound.

## Tasks

- [x] Create `HitTuning` Resource (`scripts/resources/hit_tuning.gd`) and `resources/hit_tuning.tres` with defaults.
- [x] Add `HitArea` (Area2D + CircleShape2D) child to `scenes/player.tscn`. Disabled monitoring by default.
- [x] Wire `HitArea` in `scripts/player.gd`: connect to `weapon_fired` and `dash_ended`; enable monitoring + reset hit list + deferred overlap-check on `weapon_fired`; disable on `dash_ended`. Connect `area_entered` to handle new contacts.
- [x] Add `signal hit_landed(target: Node, damage: int, position: Vector2, dash_direction: Vector2)` to `player.gd`. On each contact: skip if already hit, add to hit list, call `target.take_dash_hit(damage, dash_direction)` if available, emit `hit_landed`.
- [x] Build `scripts/dummy_enemy.gd` and `scenes/dummy_enemy.tscn`: Polygon2D visual, Area2D + CollisionShape2D, `take_dash_hit` method, white-flash via tween, `queue_free` at 0 health. Add to group `"enemy"`.
- [x] Build M3 demo scene `scenes/demos/m3_combat_demo.tscn`: same arena layout as M2, plus 3–4 dummies scattered around. Set as project main scene.
- [x] Smoke-test: dash through a row of dummies, all flash and lose 1 HP each; chained slashes finish them off; reposition dashes pass through without damage.
