# basic-enemy-ai

**Status:** Synced 2026-05-16 (amulet-gem-roster)

## Goal

Enemies chase the player and attack when in range. The dummy finally moves; engaging it becomes about positioning and timing, not standing still while you dash through it.

## Player-facing behavior

- Enemies steer toward the player each frame at `stats.move_speed`.
- Enemies stop within `stats.attack_range`. Once stopped, they wait `stats.windup_duration` seconds before damage fires; then a `1 / stats.attack_speed` cooldown before the next windup. Total attack cycle ≈ `windup_duration + 1/attack_speed`. No telegraph yet (windup is invisible delay).
- Each attack damages the player by `stats.damage`.
- Enemy facing rotates toward the player at `stats.rotation_speed` rad/s; `0` snaps instantly.
- Walls block enemies unless `stats.can_go_through_walls` is true. Enemies physically separate from each other; they don't push or pass through the player.
- Player taking damage flashes red briefly. At 0 HP the player freezes (no input, no dash) and the console logs `[Player] died`. Reload the scene to retry.

## Data

DummyEnemy refactored to a `CharacterBody2D` root so wall collision works:
- Body `CollisionShape2D` (CircleShape2D radius 8) for wall blocking. `collision_layer = 4`, `collision_mask = 5` — collides with walls (layer 1) and other enemies (layer 4); ignores the player.
- Child `Hurtbox: Area2D` with its own `CollisionShape2D` (radius 8) — the player's `HitArea` detects this. `collision_layer = 2`, `collision_mask = 0`.
- Existing `Visual` (red square) and `Arrow` Polygon2Ds stay as children.
- Group `"enemy"` moves from the Area2D root onto the new `CharacterBody2D` root.

Player body uses `collision_layer = 8`, `collision_mask = 1` so it collides with walls only — passes freely through enemies (and vice versa, since enemies' mask doesn't include layer 8).

`scripts/dummy_enemy.gd` extends `CharacterBody2D`; caches `_player` by group lookup; per-physics-frame chases or runs the windup→fire→cooldown cycle. Internal state: `_windup_remaining: float`, `_cooldown_remaining: float`, `_is_winding_up: bool`. Movement uses `move_and_slide` unless `can_go_through_walls` is true (then `global_position += step`).

Since `weapon-gem-roster`, DummyEnemy also carries gem-status state — `_burns`, `_slows`, `_stuns`, `_vulns` arrays (each entry is an independent timed instance) plus `apply_burn` / `apply_slow` / `apply_stun` / `apply_vulnerability` / `apply_knockback` duck-typed methods. AI gating: while any stun is active, movement and windup are zeroed; otherwise chase speed is scaled by `1.0 - clampf(Σ slow_pct, 0, 0.95)`. Burn instances tick fractional damage with per-instance residual carryover so sub-1 ticks accumulate.

`scripts/player.gd` gains:
- `signal damaged(amount: int, source: Node)` — emitted on each `take_damage` call. `source` is the attacking enemy node (or null for damage with no node source); added by `amulet-gem-roster` for Thorns.
- `signal died` — emitted once when health drops to 0.
- `@export var max_health: int = 5` — placeholder until amulet stats land in M5.
- `var health: int` — runtime; initialized from `max_health` in `_ready`.
- `func take_damage(amount: int, source: Node = null) -> void` — clamp health, emit `damaged`, fire `equipped_amulet_gem.on_player_damaged`, flash body red, on 0 emit `died` and disable physics + process to freeze. `DummyEnemy._do_attack` passes `self` as source.
- Adds self to group `"player"` in `_ready`.

`_try_hit` in player.gd walks up from the Hurtbox: `var enemy_root = area.get_parent()`; group + duck-typing checks happen on `enemy_root`.

Tunables — `dummy_stats.tres` updated for chasing behavior: `move_speed = 40`, `attack_range = 22`, `attack_speed = 0.8`, `damage = 1`, `rotation_speed = PI` (≈180°/s), `windup_duration = 0.5`, `can_go_through_walls = false`.

## Edge cases & out-of-scope

- `_player` null or freed: enemy idles in place.
- Player out of range during windup: windup cancels (no progress preserved); restarts on next entry into range.
- Player out of range during cooldown: cooldown ticks regardless; next windup starts once cooldown is 0 AND player is in range.
- Multiple enemies attacking the same frame: each independent; all damage applies (no per-frame cap).
- Enemy stuck against a wall: `move_and_slide` lets it slide along; no pathfinding, so it can wedge in concave geometry.
- Player dies while enemies mid-chase: enemies keep moving (they don't watch player state); harmless because `take_damage` no-ops once dead.
- Out of scope: pathfinding / nav mesh, multi-state AI (idle / patrol / flee), enemy knockback, attack telegraph / wind-up visual cue, player damage i-frames, player HUD / health bar, respawn flow, game-over UI, screen shake on damage.

## Tasks

- [x] Refactor `scenes/dummy_enemy.tscn`: root → `CharacterBody2D`; add `Hurtbox` (Area2D + CollisionShape2D radius 8) child; existing visual/arrow/body-collision under root.
- [x] Refactor `scripts/dummy_enemy.gd`: extend `CharacterBody2D`; group lookup for `_player`; per-frame chase / attack with `rotation_speed`-limited facing; honor `can_go_through_walls` (slide vs direct position).
- [x] Move `add_to_group("enemy")` from old Area2D root onto the new CharacterBody2D root.
- [x] Update `scripts/player.gd`'s `_try_hit`: `area.get_parent()` resolves the enemy root; group + `take_dash_hit` checked on the parent.
- [x] Add player damage to `scripts/player.gd`: `max_health` export, runtime `health`, `take_damage`, `damaged`/`died` signals, red modulate flash on body (with callback to restore loaded/unloaded tint), freeze on death (disable `_process` + `_physics_process` + `InputSystem.dash_in_progress = false`).
- [x] `add_to_group("player")` in `Player._ready`.
- [x] Update `resources/dummy_stats.tres` to chasing values (move_speed 40, attack_range 22, attack_speed 0.8, rotation_speed PI ≈ 3.14159).
- [x] Smoke-test in `m3_combat_demo`: 4 dummies converge on the player; an interior `WallMid` test obstacle forces the lower-row dummies to navigate around. Enemies bump but don't stack on each other; the player passes through enemies freely. In-range adjacency triggers a 0.5s windup followed by red damage flashes on the player; standing still 5+ hits later → `[Player] died` console log and the player freezes (no input, no dash).
