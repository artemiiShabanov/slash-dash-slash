class_name FeedbackTuning
extends Resource

## Tunables for the input feedback overlay (touch swipe trail + aim line).
## These are visual-feedback concerns, separate from input-system logic.

## How long a swipe trail dot lingers (s) before fading out.
@export var swipe_trail_duration: float = 0.4

## Length of the aim-line preview (px), drawn from the player along the
## current aim direction. Used for M+KB, controller, and keyboard-only.
@export var aim_line_length: float = 80.0
