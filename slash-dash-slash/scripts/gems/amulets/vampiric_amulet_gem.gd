class_name VampiricAmuletGem
extends AmuletGem

## Heals the player on every slash kill. Amount is per-kill flat; multi-kill
## slashes heal multiple times. Burn-tick kills do not trigger (no slash
## context); intentional per spec.

@export var heal_per_kill: int = 1

func on_kill(player: Node, _target: Node) -> void:
	if player == null:
		return
	# Resolve cap from the amulet's max_health; no clamp if missing.
	var cap: int = 999
	if player.equipped_amulet != null:
		cap = player.equipped_amulet.max_health
	var new_health: int = mini(cap, player.health + heal_per_kill)
	if new_health == player.health:
		return
	player.health = new_health
	# No `healed` signal yet (deferred per spec); emit damaged with a negative
	# amount as a placeholder so the HUD ledger has *something* to read.
	# Source is null because no enemy caused this.
	player.damaged.emit(-heal_per_kill, null)
