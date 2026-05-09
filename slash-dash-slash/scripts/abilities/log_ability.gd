class_name LogAbility
extends EnemyAbility

## Smoke-test ability. Prints a tagged message on each hook so the
## dispatcher wiring can be visually verified in the console.
##
## `on_tick` is throttled to ~1 Hz per enemy via a per-instance accumulator
## so the log stays readable. Multiple enemies sharing this resource each
## get their own accumulator (keyed by instance id).

const TICK_LOG_INTERVAL: float = 1.0

# Instance ID -> seconds accumulated since last tick log.
var _tick_accumulators: Dictionary = {}

func on_spawn(enemy: Node) -> void:
	print("[LogAbility] on_spawn(%s)" % enemy.name)

func on_hit(enemy: Node, damage: int, dash_direction: Vector2, is_back_hit: bool) -> void:
	var side: String = "back" if is_back_hit else "front"
	print("[LogAbility] on_hit(%s) dmg=%d side=%s dir=%s" % [enemy.name, damage, side, dash_direction])

func on_tick(enemy: Node, delta: float) -> void:
	var id: int = enemy.get_instance_id()
	var acc: float = float(_tick_accumulators.get(id, 0.0)) + delta
	if acc >= TICK_LOG_INTERVAL:
		print("[LogAbility] on_tick(%s) ~%.2fs" % [enemy.name, acc])
		acc = 0.0
	_tick_accumulators[id] = acc

func on_death(enemy: Node) -> void:
	print("[LogAbility] on_death(%s)" % enemy.name)
	_tick_accumulators.erase(enemy.get_instance_id())
