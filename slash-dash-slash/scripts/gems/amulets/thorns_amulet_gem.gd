class_name ThornsAmuletGem
extends AmuletGem

## Reflects fixed damage back to the attacker on every hit taken. Calls
## take_dash_hit with zero direction → counts as a front hit, full armor
## applies. Tune thorns_damage relative to enemy front armor (e.g., 0.9
## front × 1 thorns rounds to 0).

@export var thorns_damage: int = 1

func on_player_damaged(_player: Node, _amount: int, source: Node) -> void:
	if source == null or not is_instance_valid(source):
		return
	if not source.has_method("take_dash_hit"):
		return
	source.take_dash_hit(thorns_damage, Vector2.ZERO)
