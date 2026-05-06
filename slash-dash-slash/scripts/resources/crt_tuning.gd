class_name CRTTuning
extends Resource

## Tunables for the global CRT post-process. Stored in
## `res://resources/crt_tuning.tres`. The `CRTOverlay` autoload reads this
## resource and pushes values to the post-process shader.
##
## Per-floor mood variation is not in scope yet, but this resource shape lets
## a future floor-content spec swap or animate these values without code change.

## Multiplicative phosphor tint applied to the rendered frame. Slightly bluish
## by default — reads as a cool monochrome CRT. Nudge toward green for terminal
## floors, toward amber for warmer rooms.
@export var tint_color: Color = Color(0.92, 0.95, 1.0, 1.0)

## Barrel curvature strength. 0 = flat screen; ~0.02 = subtly curved CRT glass;
## ~0.04 = obvious bulge. Above ~0.05 the corners eat too much canvas.
@export_range(0.0, 0.05) var curvature: float = 0.018

## Scanline darkening. 0 = none; 1 = every other row goes black.
@export_range(0.0, 1.0) var scanline_intensity: float = 0.18

## Per-channel UV offset for chromatic aberration. R goes right, B goes left.
@export_range(0.0, 0.01) var chromatic_aberration: float = 0.002

## Vignette darkness at corners (0..1).
@export_range(0.0, 1.0) var vignette_intensity: float = 0.15

## CRT signal noise intensity (0..0.3). Replaces the old film grain — sells the
## "live signal" feel rather than aged celluloid.
@export_range(0.0, 0.3) var noise_intensity: float = 0.03

## If true, the noise pattern shifts each frame (animated). False = static
## per-frame noise (cheaper, less alive).
@export var noise_animated: bool = true
