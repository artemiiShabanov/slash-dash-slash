class_name EnemyStats
extends Resource

## Universal stat block for any enemy. One Resource class, many `.tres`
## instances per archetype (dummy_stats.tres, manager_stats.tres, ...).
##
## Per-instance runtime state (facing, current health) lives on the enemy
## node, not here. The `abilities` array (composable behaviors) is added by
## `enemy-ability-base` in a follow-up spec.

## Template HP. The enemy node initializes its runtime `health` from this.
@export var max_health: int = 3

## Damage the enemy deals to the player on a successful attack.
@export var damage: int = 1

## Attacks per second (used by AI-driven attacks; not yet read by the dummy).
@export var attack_speed: float = 1.0

## Pixels per second cap for AI movement.
@export var move_speed: float = 60.0

## Pixels; AI begins attacking when the player is within this range.
@export var attack_range: float = 16.0

## Seconds the enemy stands still in range before damage fires. 0 = no delay,
## attack is instant on entering range. Cancelled if the player leaves range
## during the windup (no progress preserved).
@export var windup_duration: float = 0.0

## Radians per second; rate at which AI rotates the enemy's `facing`.
@export var rotation_speed: float = 0.0

## Damage reduction in [0, 1] for hits coming from the front (D · facing < 0).
@export_range(0.0, 1.0) var armor_front: float = 0.9

## Damage reduction in [0, 1] for hits coming from behind (D · facing > 0).
@export_range(0.0, 1.0) var armor_back: float = 0.0

## When true, the enemy's collision/movement skips wall blocking.
@export var can_go_through_walls: bool = false

## Composable behaviors attached to this enemy. The dispatcher on the enemy
## node iterates this array and calls hooks (on_spawn, on_hit, on_tick,
## on_death). See `enemy-ability-base` spec.
@export var abilities: Array[EnemyAbility] = []
