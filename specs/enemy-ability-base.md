# enemy-ability-base

**Status:** Synced 2026-05-09

## Goal

Composable behavior for enemies. Each `EnemyStats` carries a list of abilities (Resources) — explode-on-death, burn aura, on-hit counter — without expanding the stats schema. One dispatcher iterates the list and calls hooks at the right moments.

## Player-facing behavior

- Same gameplay; this spec adds plumbing, not effects yet. The dummy gains a `LogAbility` so console output proves the dispatcher fires.
- On Floor B+ enemies authored later, multiple abilities can stack on one enemy: e.g. `[BurnAura, ExplodeOnDeath]`. No script change per combination.

## Data

`EnemyAbility` Resource (`scripts/abilities/enemy_ability.gd`, `class_name EnemyAbility`). Abstract base; subclasses override hooks. Default implementations are no-ops:

- `on_spawn(enemy: Node) -> void`
- `on_hit(enemy: Node, damage: int, dash_direction: Vector2, is_back_hit: bool) -> void`
- `on_tick(enemy: Node, delta: float) -> void`
- `on_death(enemy: Node) -> void`

`EnemyStats.abilities: Array[EnemyAbility]` (default empty) holds the list — see `enemy-stats-resource` (synced).

Dispatcher (on the enemy node, currently `DummyEnemy`):
- `_ready` → loop `stats.abilities` and call `on_spawn(self)`.
- `_physics_process(delta)` → loop and call `on_tick(self, delta)`.
- `take_dash_hit(...)` → after side+damage are computed, loop and call `on_hit(self, final_damage, dash_direction, is_back_hit)`. Fires on every hit, including 0-damage front-armor blocks.
- Death (`health <= 0`) → loop and call `on_death(self)` *before* `queue_free`.

`LogAbility` (`scripts/abilities/log_ability.gd`, `class_name LogAbility`) — concrete subclass overriding all four hooks to `print` a tagged message. Smoke-test only.

`resources/abilities/log_ability.tres` — single instance assigned to `dummy_stats.tres`'s `abilities` array.

## Edge cases & out-of-scope

- `abilities` empty or null: dispatcher loops over nothing; zero overhead, no warning.
- Mutating `stats.abilities` from inside a hook: undefined in v1; authors must not.
- Ability calls back into `take_dash_hit` recursively from `on_hit`: undefined; authors must not.
- Out of scope: pre-hit damage mutator hook, hook return values, ability ordering / priority, ability-removal mid-run, status effects, save/load of ability state, concrete content beyond `LogAbility`.

## Tasks

- [x] Create `EnemyAbility` Resource (`scripts/abilities/enemy_ability.gd`) with the four virtual hooks (empty default bodies).
- [x] Add `abilities: Array[EnemyAbility]` field to `EnemyStats` (`scripts/resources/enemy_stats.gd`); default empty.
- [x] Add the four dispatch helpers to `scripts/dummy_enemy.gd` and call them at the right moments (`_ready`, `_physics_process`, end of `take_dash_hit`, before `queue_free` on death).
- [x] Create `LogAbility` (`scripts/abilities/log_ability.gd`) overriding the four hooks with tagged `print` calls. To keep console readable, `on_tick` only prints once per second (per-instance accumulator keyed by enemy `instance_id`).
- [x] Create `resources/abilities/log_ability.tres` and assign it into `dummy_stats.tres`'s `abilities` array.
- [x] Smoke-test in `m3_combat_demo`: console shows `on_spawn` for each dummy at startup, `on_tick` ~once per second per dummy, `on_hit` on each contact, `on_death` once per dummy when killed.
