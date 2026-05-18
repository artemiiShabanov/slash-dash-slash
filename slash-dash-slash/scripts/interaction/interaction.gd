class_name Interaction
extends Resource

## Per-prop behavior Resource attached to an `Interactable` node. The player
## fires `on_dash_into` once per dash contact (gated on `Interactable.consumed`).
## Subclasses override the hook for their effect — heal-drop, loot-drop, door,
## etc. Pillar 1: dash is the only verb.

## When true, the player's dash terminates at the interactable (like a wall
## hit). Doors / dark gem / NPC dialogue land here. Pass-through props
## (water cooler, vending machine) leave this false.
@export var stops_dash: bool = false

## Fired by Player on dash contact. `interactable` is the root node carrying
## this Interaction; subclasses may flip `interactable.consumed`, mutate
## visuals, or spawn pickups.
func on_dash_into(_player: Node, _interactable: Node) -> void:
	pass
