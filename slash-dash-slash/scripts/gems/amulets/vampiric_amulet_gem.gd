class_name VampiricAmuletGem
extends AmuletGem

## Heals the player on every slash kill. Amount is per-kill flat; multi-kill
## slashes heal multiple times. Burn-tick kills do not trigger (no slash
## context); intentional per spec.

@export var heal_per_kill: int = 1

func on_kill(player: Node, _target: Node) -> void:
	if player == null:
		return
	# Routes through Player._set_health: single mutation point that clamps to
	# amulet cap, emits health_changed for HUD, and emits damaged(prev-new) so
	# the debug damage_number_spawner continues to render a heal popup.
	if player.has_method("_set_health"):
		player._set_health(player.health + heal_per_kill, null)
