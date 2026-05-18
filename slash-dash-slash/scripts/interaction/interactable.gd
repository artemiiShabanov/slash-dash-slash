extends Area2D
class_name Interactable

## Attach to an Area2D root for any prop the player can dash into. Holds the
## behavior `Interaction` Resource + a runtime `consumed` flag so single-use
## props (water cooler) ignore repeat contacts.
##
## Layer: INTERACTABLE_LAYER = 16. Player's InteractArea masks this so it
## triggers `area_entered` during a dash.

const INTERACTABLE_LAYER: int = 16

@export var interaction: Interaction
var consumed: bool = false

func _ready() -> void:
	# Defensive: enforce the layer at runtime so authoring mistakes don't
	# silently break detection.
	collision_layer = INTERACTABLE_LAYER
