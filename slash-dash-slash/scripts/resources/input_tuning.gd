class_name InputTuning
extends Resource

## Tunables for the input system. All numeric values live here; never hardcode
## input thresholds or visual feedback durations in scene scripts.

## Minimum finger travel (px) before a touch gesture is treated as a swipe.
@export var swipe_min_distance: float = 40.0

## Maximum gesture duration (s). Longer touches are treated as drags and ignored.
@export var swipe_max_duration: float = 0.5

## Joystick deadzone (0..1). Below this magnitude the stick is treated as centered.
@export var controller_stick_deadzone: float = 0.2
