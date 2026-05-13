# armor-direction

**Status:** Synced 2026-05-09

## Goal

Make approach angle matter. An enemy hit from behind takes more damage than one hit from the front; choosing *where to dash from* becomes a real skill axis on top of timing.

## Player-facing behavior

- Each enemy has a visible facing direction (small arrow on the sprite).
- A slash dash hits from the **front** when the dash vector opposes facing; from the **back** when it aligns with facing.
- Front hits are reduced by `armor_front`; back hits by `armor_back`.
- Flash color differs by side: front hit = dim "deflected" flash; back hit = bright "vulnerable" flash. Same dummy, different read at a glance.
- Reposition dashes (sword unloaded) don't hit at all — no armor check needed.

## Data

- Enemy fields:
  - `facing: Vector2` — unit vector, default `Vector2.RIGHT`. Per-instance `@export` on the enemy node (runtime state mutated by AI).
  - `armor_front: float` — damage reduction in `[0, 1]`, sourced from `EnemyStats.armor_front` (since `enemy-stats-resource`).
  - `armor_back: float` — damage reduction in `[0, 1]`, sourced from `EnemyStats.armor_back`.
- `take_dash_hit(damage, dash_direction) -> Dictionary`:
  - `dot = dash_direction.dot(facing)`; `dot > 0` → back hit, else → front hit.
  - `final_damage = maxi(0, roundi(damage * (1.0 - armor)))`.
  - Returns `{"final_damage": final_damage, "is_back_hit": is_back_hit}` so the player's `hit_landed` signal can be populated without recomputing the side. (Drift introduced when `audio_sfx_palette` shipped.)
- Flash color constants on `DummyEnemy`:
  - `FLASH_FRONT: Color = Color(1.3, 1.3, 1.3, 1)` — mild brighten.
  - `FLASH_BACK: Color = Color(3.0, 3.0, 3.0, 1)` — strong overbright.

## Edge cases & out-of-scope

- `facing == Vector2.ZERO`: treat as front hit (default to the safer-for-enemy side).
- Damage rounds to zero: enemy still flashes (player gets feedback that contact landed) but health is unchanged.
- Out of scope: side armor (third bucket), armor-piercing modifiers, per-element resistance, hit-stop / screen shake / sound, damage numbers. AI-driven facing rotation now in (per `basic-enemy-ai`); `EnemyStats` resource now exists.

## Tasks

- [x] Add `facing: Vector2`, `armor_front: float`, `armor_back: float` `@exports` to `scripts/dummy_enemy.gd`.
- [x] Add a small arrow Polygon2D (`Arrow`) child to `scenes/dummy_enemy.tscn` whose rotation tracks `facing` at `_ready`.
- [x] Update `take_dash_hit(damage, dash_direction)`: compute side via dot product, apply armor reduction with `roundi`/`maxi(0, …)`, decrement health if final > 0, flash with the side-specific color.
- [x] Replace the existing flat-color `_flash()` with a `_flash(color: Color)` helper that takes the side color.
- [x] Update `scenes/demos/m3_combat_demo.tscn`: set distinct facings on the four dummies (right, down, left, up).
- [x] Smoke-test: dash through each dummy from front (dim flash, often 0 damage) and back (bright flash, full damage); facings on the dummies are clearly readable from the arrows.
