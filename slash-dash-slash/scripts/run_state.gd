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

## Weapon gems equipped this run. Bounded by `equipped_sword.gem_slot_count`
## at insertion time (enforced by upgrade-card-draft when it lands).
var equipped_weapon_gems: Array[WeaponGem] = []

## Amulet gem equipped this run (one slot per amulet, per GDD).
var equipped_amulet_gem: AmuletGem = null

## Wipes all run-time selections. Called by the equipment-selection scene
## on enter so leftover state from a previous run doesn't bleed in.
func reset() -> void:
	chosen_sword = null
	chosen_amulet = null
	equipped_weapon_gems = []
	equipped_amulet_gem = null
