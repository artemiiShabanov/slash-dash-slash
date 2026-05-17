class_name WallPassAmuletGem
extends AmuletGem

## Dashes phase through walls — the player drops its collision_mask on equip,
## restoring on unequip. wall_hit never emits while equipped because no
## collision occurs to detect.

var _prior_mask: int = -1

func on_equip(player: Node) -> void:
	if player == null:
		return
	_prior_mask = player.collision_mask
	player.collision_mask = 0

func on_unequip(player: Node) -> void:
	if player == null or _prior_mask < 0:
		return
	player.collision_mask = _prior_mask
	_prior_mask = -1
