class_name EnemyAbility
extends Resource

## Abstract base for composable enemy behaviors. Each subclass overrides
## the hooks it cares about; unimplemented hooks stay no-ops.
##
## The dispatcher on the enemy node iterates `EnemyStats.abilities` and
## calls the corresponding hook at the right moment:
##   _ready                -> on_spawn
##   _physics_process      -> on_tick
##   take_dash_hit         -> on_hit
##   death (pre-queue_free) -> on_death

func on_spawn(_enemy: Node) -> void:
	pass

func on_hit(_enemy: Node, _damage: int, _dash_direction: Vector2, _is_back_hit: bool) -> void:
	pass

func on_tick(_enemy: Node, _delta: float) -> void:
	pass

func on_death(_enemy: Node) -> void:
	pass
