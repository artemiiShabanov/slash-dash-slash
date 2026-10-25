# enemy

**Status:** Shipped (consolidated 2026-05-19, supersedes `enemy-stats-resource`, `enemy-ability-base`, `basic-enemy-ai`)

## Goal

One spec for everything that defines a non-player creature: the universal stat block, composable per-instance abilities, the chase/attack AI, and the live status state (burn/slow/stun/vulnerability) consumed by gem effects.

## Player-facing behavior

- Enemies chase the player at `stats.move_speed`, rotating their facing arrow toward the player at `stats.rotation_speed` rad/s. Walls block unless `can_go_through_walls`.
- Within `stats.attack_range`, the enemy stops, runs a `stats.windup_duration` invisible windup, deals `stats.damage` to the player, then waits `1 / stats.attack_speed` cooldown before another windup.
- The player taking damage flashes red; at 0 HP the player freezes and the console logs `[Player] died`. Reload the scene to retry.
- Each enemy has a visible facing arrow — front hits chip with `armor_front`, back hits hurt with `armor_back` (see `combat-hit-resolution`).
- Status effects from gem procs are visible: orange tint while burning, ice-blue tint while stunned, soft blue tint while slowed. Stuns freeze movement + windup; slows scale chase speed (cap 95%, never tips into stun).

## Data

`EnemyStats` (`scripts/resources/enemy_stats.gd`, `class_name EnemyStats`):
- `max_health: int`
- `damage: int` — per-attack damage dealt to the player.
- `attack_speed: float` — attacks per second.
- `move_speed: float` — chase cap in pixels/sec.
- `attack_range: float` — pixels; in-range triggers windup.
- `windup_duration: float` — seconds standing still before damage fires; cancelled by leaving range.
- `rotation_speed: float` — rad/s; `0` snaps instantly.
- `armor_front: float` / `armor_back: float` — damage reduction in `[0, 1]`.
- `can_go_through_walls: bool`.
- `abilities: Array[EnemyAbility]` — composable hooks (see below).

`EnemyAbility` (`scripts/abilities/enemy_ability.gd`, `class_name EnemyAbility`) — abstract Resource; subclasses override:
- `on_spawn(enemy: Node)`, `on_hit(enemy, damage, dash_direction, is_back_hit)`, `on_tick(enemy, delta)`, `on_death(enemy)`. Default no-op.
- `LogAbility` is the verification subclass (prints tagged messages).

Enemy node (`scripts/dummy_enemy.gd`, `extends CharacterBody2D`) — placeholder for the M3/M4 demo; same shape future enemies follow.
- Group: `"enemy"` on the CharacterBody2D root. Layers: body 4 / mask 5 (walls + other enemies); child `Hurtbox` Area2D layer 2 (player HitArea target).
- Runtime state: `health: int` (init from `stats.max_health`), `facing: Vector2`, `_windup_remaining`, `_cooldown_remaining`, `_is_winding_up`, `_player` (group lookup, cached).
- Status state — parallel independent timers, pruned in `_physics_process`:
  - `_burns`: `[{damage_per_tick, tick_interval, time_to_next_tick, time_remaining, residual}]`
  - `_slows`: `[{slow_pct, time_remaining}]`
  - `_stuns`: `[{time_remaining}]`
  - `_vulns`: `[{damage_mult, time_remaining}]`
- Status interface (duck-typed; consumed by gem dispatchers in `gems`):
  - `apply_burn(damage_per_tick, tick_interval, duration)` / `apply_slow(slow_pct, duration)` / `apply_stun(duration)` / `apply_vulnerability(damage_mult, duration)` / `apply_knockback(direction, distance)` (one-shot shove, not stored).
- AI gating: stunned → skip chase, cancel windup, zero velocity. Slowed → multiply chase speed by `1.0 - clampf(Σ slow_pct, 0, 0.95)`. Burn ticks deal fractional damage with per-instance `residual` carryover so sub-1 ticks accumulate; burn-kill triggers `_dispatch_on_death` + `queue_free` (no `hit_landed` — that signal is dash-scoped).
- Status tint priority: stun > burn > slow > white. Stomped briefly by the white/colored hit flash; reasserts next physics frame.
- Combat: `take_dash_hit(damage, dash_direction) -> {final_damage, is_back_hit, killed}` (see `combat-hit-resolution`). Vulnerability product applied after armor before returning. `_do_attack` calls `player.take_damage(stats.damage, self)`; reentrancy guard (`is_instance_valid(self)`) after the call protects against Thorns-style reflection killing the attacker mid-attack.

Dispatcher: enemy node iterates `stats.abilities` and calls hooks at `_ready` (on_spawn), `_physics_process` (on_tick), end of `take_dash_hit` (on_hit, includes 0-damage front-armor blocks), before `queue_free` on death (on_death). Burn ticks also fire `_dispatch_on_hit` so abilities see them.

Tunable instances — `res://resources/dummy_stats.tres`, `tank_dummy_stats.tres`. Defaults at `move_speed=40, attack_range=22, attack_speed=0.8, damage=1, windup_duration=0.5, rotation_speed=PI`. Player layers: `collision_layer=8, collision_mask=1` so player passes freely through enemies (and vice versa) but collides with walls.

## Edge cases & out-of-scope

- `stats == null`: `push_warning`, fall back to a hardcoded `EnemyStats.new()` so smoke tests don't crash.
- `_player` null or freed: enemy idles in place.
- Player out of range during windup: windup cancels (no progress preserved).
- Player out of range during cooldown: cooldown ticks regardless; next windup starts when cooldown ≤ 0 AND in range.
- Multiple enemies attacking the same frame: each independent; no per-frame cap.
- Stuck against walls: `move_and_slide` lets it slide; no pathfinding, can wedge in concave geometry.
- Enemy mutating its own `stats.abilities` from inside a hook: undefined.
- Slow stack > 95%: capped (never 100% — stun's job).
- Knockback past walls: bypasses move_and_slide (Area2D-driven), can clip. Placeholder until a real knockback impulse path lands.
- Out of scope: pathfinding / nav mesh, multi-state AI (patrol / flee), attack telegraph visual, player damage i-frames, HUD / health bar, respawn flow, game-over UI, enemy roster content (per-floor).
