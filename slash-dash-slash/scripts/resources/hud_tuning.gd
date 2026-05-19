class_name HudTuning
extends Resource

## Tunables shared by the HUD layer (heart pips, player status icons,
## equipment chip). Stored at `res://resources/hud_tuning.tres`.

# ===== Player-relative pips =====

## Heart row offset above the stamina pips.
@export var health_offset: Vector2 = Vector2(0, -8)

## Status-icon strip offset below the stamina pips.
@export var status_offset: Vector2 = Vector2(0, 8)

## Pixels between heart centers (and between status icons).
@export var pip_spacing: float = 5.0

## Seconds for a heart to fade in on refill. Drain is instant.
@export var pip_fade_duration: float = 0.2

@export var heart_filled_color: Color = Color(0.78, 0.15, 0.25, 1.0)
@export var heart_drained_color: Color = Color(0.30, 0.18, 0.20, 0.4)

# ===== Equipment chip =====

## Side length in px for one icon slot (sword / amulet / gem). 640x360
## viewport keeps this small.
@export var icon_size: int = 14

## Border color around each slot frame. Defaults to dot_matrix_green.
@export var slot_frame_color: Color = Color(0.34, 0.78, 0.42, 1.0)

## Alpha multiplier on the inner fill of an empty (unfilled) gem slot.
@export_range(0.0, 1.0) var slot_empty_alpha: float = 0.25

## Top-left margin of the equipment chip relative to viewport edge.
@export var chip_padding: Vector2 = Vector2(6, 6)

## Pixels between the four icon groups (sword | amulet | gems | amulet gem).
@export var chip_separator_width: int = 4
