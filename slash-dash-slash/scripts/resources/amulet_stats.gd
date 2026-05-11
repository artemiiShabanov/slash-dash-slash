class_name AmuletStats
extends Resource

## Amulet equipment. Owns survival and dash-reach tunables.
##
## One `.tres` per amulet archetype. The Player references one as
## `equipped_amulet` and reads its fields directly.

## Player template HP. The Player initializes its runtime `health` from this.
@export var max_health: int = 5

## HP per second regenerated continuously. Not consumed yet.
@export var health_regen_rate: float = 0.0

## Number of discrete hit-absorbers stacked above HP. Not consumed yet.
@export var shield_count: int = 0

## Seconds per +1 shield restored. Not consumed yet.
@export var shield_regen_interval: float = 0.0

## Base pixel distance per dash before modifiers (gem / world-state stacks).
@export var dash_distance: float = 80.0

## Slot for the future `AmuletEffect` hook resource. Null for M5.
@export var amulet_effect: Resource
