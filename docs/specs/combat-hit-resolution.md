# combat-hit-resolution

**Status:** Shipped (consolidated 2026-05-19, supersedes `hit-detection`, `armor-direction`)

## Goal

One spec for "a slash dash hit lands and an enemy resolves the damage." Covers the HitArea, the per-contact dispatch, side calculation, and the layered damage pipeline (sword base × gem multiplier × armor × vulnerability).

## Player-facing behavior

- A slash dash damages every enemy whose body the player passes through, exactly once per dash.
- A reposition dash (sword unloaded) deals no damage; the HitArea stays inactive.
- Each enemy has a visible **facing arrow**. Front hits (dash vector opposes facing) are reduced by `armor_front`; back hits (dash vector aligns with facing) are reduced by `armor_back`. Side is decided by `dash_direction.dot(facing)`.
- Front flash is a dim "deflected" brighten; back flash is a strong overbright — same dummy, different read at a glance.
- A procced slash colors the per-enemy flash with the proc element (or blended mean for combos) instead of plain white.

## Data

Signal (player): `hit_landed(target: Node, final_damage: int, position: Vector2, dash_direction: Vector2, is_back_hit: bool)`. Emitted after each per-enemy contact during a slash dash. `final_damage` is the enemy-resolved amount that actually came off HP — post-armor, post-vulnerability.

State (player): `_hit_this_dash: Dictionary` — per-dash hit set, cleared on `weapon_fired`.

`HitArea` (Area2D child of the player, `CircleShape2D`):
- Radius = `(body_radius + hit_tuning.hit_radius_offset + ctx.extra_hit_radius) × ctx.hit_radius_multiplier`. Computed at `weapon_fired` after the gem roll; restored to baseline at `dash_ended`.
- `monitoring` toggled on at `weapon_fired`, off at `dash_ended`. On enable, a deferred `get_overlapping_areas` sweep catches enemies already inside the radius.
- Layer 0, mask 2 (enemy hurtbox layer).

Per-contact dispatch (`Player._try_hit`):
1. Walk up `area.get_parent()` → enemy root (CharacterBody2D in group `"enemy"`).
2. Skip if already in `_hit_this_dash`; otherwise add.
3. Compute `dealt_damage = roundi(equipped_sword.base_damage × ctx.damage_multiplier)`.
4. Call `enemy_root.take_dash_hit(dealt_damage, _dash_direction)` → returns `{final_damage, is_back_hit, killed}`.
5. Emit `hit_landed`; tween the enemy root's `modulate` to `ctx.flash_color` for `proc_flash_duration` if any proc fired; dispatch per-element per-contact effects from `ctx.tags` (`fire_proc` → apply_burn, `water_proc` → apply_vulnerability, `ice_proc` → apply_slow, `wind_proc` → apply_knockback, `lightning_proc` → apply_stun); if `killed`, fire `equipped_amulet_gem.on_kill(self, enemy_root)`.

Tunables — `res://resources/hit_tuning.tres` (`class_name HitTuning`):
- `hit_radius_offset: float` — additive forgiveness margin past body radius (default 2.0).

Enemy interface (duck-typed): `take_dash_hit(damage: int, dash_direction: Vector2) -> Dictionary`. Returns `{final_damage: int, is_back_hit: bool, killed: bool}`. Any node implementing this participates. Side + armor + vulnerability calc lives inside the enemy (see `enemy`):
- `is_back_hit = facing.length() > 0 and dash_direction.dot(facing) > 0`.
- `armored = maxi(0, roundi(damage × (1 - armor)))` where armor = `stats.armor_back` or `stats.armor_front`.
- `final_damage = roundi(armored × Π vulnerability_stack)` (vulnerability factor from WATER procs).
- `killed = (health - final_damage) ≤ 0`.

Flash colors (enemy side):
- `FLASH_FRONT = Color(1.3, 1.3, 1.3, 1)` — mild brighten.
- `FLASH_BACK = Color(3.0, 3.0, 3.0, 1)` — strong overbright.

## Edge cases & out-of-scope

- Enemy already overlapping at `weapon_fired`: caught by the deferred `get_overlapping_areas` sweep on enable.
- Enemy entering the area after dash end: ignored — monitoring is off.
- Same enemy entering/leaving/re-entering during one dash: hit once total.
- `facing == Vector2.ZERO`: treated as front hit (safer-for-enemy default).
- Damage rounds to zero: enemy still flashes (feedback) but health is unchanged.
- Out of scope: side armor (third bucket), armor-piercing, per-element resistance, hit-stop, screen shake, particles, knockback beyond gem-driven WIND.
