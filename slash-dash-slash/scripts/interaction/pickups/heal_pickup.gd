extends Pickup
class_name HealPickup

## Restores HP to the player on contact. Reuses Vampiric's placeholder
## `damaged(-N, null)` emit so the HUD ledger sees the heal until a real
## `healed` signal lands.

@export var heal_amount: int = 1

func _apply_payload(player_node: Node) -> void:
	if player_node == null or not "health" in player_node:
		return
	var cap: int = 999
	if "equipped_amulet" in player_node and player_node.equipped_amulet != null:
		cap = player_node.equipped_amulet.max_health
	var new_health: int = mini(cap, player_node.health + heal_amount)
	if new_health == player_node.health:
		return
	player_node.health = new_health
	# Placeholder heal popup signal; mirrors VampiricAmuletGem until a
	# dedicated `healed` signal exists.
	if player_node.has_signal("damaged"):
		player_node.damaged.emit(-heal_amount, null)
