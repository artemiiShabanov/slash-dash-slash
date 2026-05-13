class_name LogWeaponGem
extends WeaponGem

## Debug subclass that prints on every weapon-gem hook so the dispatcher
## wiring can be visually verified. Not a "seventh element" — its `element`
## field still points at one of the six real kinds; the subclass exists
## purely so we can override hooks without polluting the real `on_*`
## bodies in `WeaponGem`.

func on_slash(_player: Node, target: Node, dash_direction: Vector2) -> void:
	var target_name: String = target.name if target != null else "null"
	print("[LogWeaponGem:%s] on_slash target=%s dir=%s" % [Element.display_name(element), target_name, dash_direction])

func on_proc(_player: Node, target: Node, dash_direction: Vector2) -> void:
	var target_name: String = target.name if target != null else "null"
	print("[LogWeaponGem:%s] on_proc target=%s dir=%s" % [Element.display_name(element), target_name, dash_direction])

func on_kill(_player: Node, target: Node) -> void:
	var target_name: String = target.name if target != null else "null"
	print("[LogWeaponGem:%s] on_kill target=%s" % [Element.display_name(element), target_name])

func on_combo(_player: Node, partner_gems: Array, target: Node) -> void:
	var target_name: String = target.name if target != null else "null"
	print("[LogWeaponGem:%s] on_combo partners=%d target=%s" % [Element.display_name(element), partner_gems.size(), target_name])
