extends Pickup
class_name HealPickup

## Restores HP to the player on contact. Reuses Vampiric's placeholder
## `damaged(-N, null)` emit so the HUD ledger sees the heal until a real
## `healed` signal lands.

@export var heal_amount: int = 1

func _apply_payload(player_node: Node) -> void:
	if player_node == null or not "health" in player_node:
		return
	# Routes through Player._set_health: single mutation point that clamps,
	# emits health_changed for HUD, and emits damaged(prev-new) so the debug
	# damage_number_spawner renders a heal popup.
	if player_node.has_method("_set_health"):
		player_node._set_health(player_node.health + heal_amount, null)
