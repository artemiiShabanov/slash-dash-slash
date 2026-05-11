class_name DashTuning
extends Resource

## Tunables for the player's core dash (motion + trail).
## Stored at `res://resources/dash_tuning.tres`.
##
## Distance/duration are *base* values. Per-dash effective values are computed
## from base + modifier registries on the player (set via `set_dash_distance_modifier`
## and `set_dash_duration_modifier`). Empty registries here in M2 — amulets, gems,
## and world-state will populate them later.

## Seconds from dash start to dash end before modifiers.
## Dash distance now lives on `AmuletStats.dash_distance`; the amulet owns reach.
@export var base_dash_duration: float = 0.12

## Speed-over-time profile. The integral over [0,1] is normalized internally so
## the cumulative motion always equals the effective dash distance regardless of
## the curve's shape. Default ease-out: high speed at t=0, low speed at t=1.
@export var speed_curve: Curve

## Per-frame smoothing factor applied to sprite rotation while idle.
## 0 = never rotates; 1 = snaps instantly to aim. Frame-rate dependent.
@export_range(0.0, 1.0) var idle_rotation_lerp: float = 0.5

## Maximum number of points retained in the dash trail. Older points drop off
## the head as the line grows past this length.
@export var trail_max_points: int = 32

## Seconds for the trail to fade from full to invisible after a dash ends.
@export var trail_fade_duration: float = 0.25

## Reposition (non-slash) trail tint. Default = palette `dot_matrix_green` to
## read as a phosphor streak under the CRT post-process.
@export var trail_color: Color = Color(0.34, 0.78, 0.42, 1.0)

## Reposition trail line width (px in 640x360 internal frame).
@export var trail_width: float = 2.0

## Slash trail tint — used when the dash fires the sword. Default = palette
## `blood_red` to read as a weapon strike vs. the green reposition phosphor.
@export var slash_trail_color: Color = Color(0.65, 0.16, 0.13, 1.0)

## Slash trail line width — wider than reposition so a slash visually carries
## more weight even before juice/SFX layers land.
@export var slash_trail_width: float = 4.0
