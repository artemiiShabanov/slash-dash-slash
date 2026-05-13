extends Node

## RunState autoload.
##
## Holds per-run state set at run-start (equipment selection) and read by
## downstream systems (Player on _ready). Persists across scene changes for
## the duration of a run; cleared on entering the selection scene again.
##
## Future fields land here as the game grows: in-run kills, gems found,
## quest progress, etc.

var chosen_sword: SwordStats = null
var chosen_amulet: AmuletStats = null

## Wipes all run-time selections. Called by the equipment-selection scene
## on enter so leftover state from a previous run doesn't bleed in.
func reset() -> void:
	chosen_sword = null
	chosen_amulet = null
