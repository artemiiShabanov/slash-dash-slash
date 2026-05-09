# enemy-stats-resource

**Status:** Shipped

## Goal

Define the universal property bag every enemy reads from. One Resource class, many `.tres` instances per enemy archetype — armor / health / speed / range tuned in the editor without script changes.

## Player-facing behavior

- No new player-facing behavior. This spec is data shape; `basic-enemy-ai` consumes it next.
- Dummy enemies behave identically to before (same defaults), but their numbers now live in `resources/dummy_stats.tres` instead of inline `@exports`.

## Data

`EnemyStats` Resource (`scripts/resources/enemy_stats.gd`, `class_name EnemyStats`):

- `max_health: int` — template HP; runtime tracks current separately on the enemy.
- `damage: int` — per-attack damage dealt to the player.
- `attack_speed: float` — attacks per second.
- `move_speed: float` — pixels/second cap for AI movement.
- `attack_range: float` — pixels; AI begins attacking when player is within.
- `rotation_speed: float` — radians/second; rate at which AI rotates `facing` toward the player.
- `armor_front: float` — damage reduction in `[0, 1]` for front hits.
- `armor_back: float` — damage reduction in `[0, 1]` for back hits.
- `can_go_through_walls: bool` — disables wall collision when true.

Per-instance runtime state stays on the enemy node (not in stats):
- `facing: Vector2` — orientation, mutated by AI.
- `health: int` — current HP, initialized from `stats.max_health` at `_ready`.

`abilities: Array[EnemyAbility]` is intentionally NOT in this spec; `enemy-ability-base` adds the field via /sync drift here.

## Edge cases & out-of-scope

- `stats == null` on an enemy: push_warning, fall back to a hardcoded safe-default `EnemyStats.new()` so smoke tests don't crash.
- Per-instance overrides: handled by editing the stats sub-resource inline in the scene OR by pointing the instance to a different `.tres`.
- Out of scope: composable abilities array, per-element resistances, status effects, AI behaviors, enemy roster content, save/load of mutated stats mid-run.

## Tasks

- [x] Create `EnemyStats` Resource (`scripts/resources/enemy_stats.gd`) with the field list above.
- [x] Create `resources/dummy_stats.tres` with placeholder values matching current DummyEnemy defaults (max_health=3, damage=1, attack_speed=1.0, move_speed=60.0, attack_range=16.0, rotation_speed=0.0, armor_front=0.9, armor_back=0.0, can_go_through_walls=false).
- [x] Migrate `scripts/dummy_enemy.gd`: replace `max_health`, `armor_front`, `armor_back` `@exports` with `@export var stats: EnemyStats`; read those values via `stats.*`. Keep `facing` and runtime `health` as before. `_ready` initializes `health = stats.max_health`.
- [x] Update `scenes/dummy_enemy.tscn` to reference `dummy_stats.tres`.
- [x] Verify `m3_combat_demo.tscn` runs identically (4 dummies, same flash colors, same per-side damage). No instance changes needed since all current dummies share defaults.
