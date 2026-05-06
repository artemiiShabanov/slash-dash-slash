class_name Palette
extends Resource

## Named-color palette for the entire game. Single source of truth for any
## palette-driven drawing. The default Theme references these values directly
## (hardcoded for now); custom drawing code should load this resource and read
## colors by name rather than inlining literals.
##
## Values in `resources/palette.tres` are tunable; the field names are stable.

# ===== Paper / office surfaces =====

## Base tint of paper, cubicle walls, document backgrounds.
@export var paper_yellow: Color = Color(0.96, 0.91, 0.74)

## Cream — neutral panel / card background.
@export var bone_white: Color = Color(0.92, 0.89, 0.81)

# ===== Text =====

## Primary text on paper. Slightly warm; not pure black.
@export var ink_black: Color = Color(0.07, 0.06, 0.05)

## Bright UI text on dark backgrounds; slightly green-tinted fluorescent feel.
@export var fluorescent_white: Color = Color(0.96, 0.97, 0.92)

## Secondary text, disabled states.
@export var shadow_grey: Color = Color(0.45, 0.42, 0.38)

# ===== Terminal / CRT accents =====

## Old-monitor green for terminal-style highlights.
@export var dot_matrix_green: Color = Color(0.34, 0.78, 0.42)

# ===== Floor / mood accents =====

## Wood paneling, executive accents (Floor 7).
@export var desk_brown: Color = Color(0.36, 0.24, 0.16)

## Alerts, damage, the Dark Gem's dialogue.
@export var blood_red: Color = Color(0.65, 0.16, 0.13)

## Desaturated wash for the Archives floor.
@export var archive_dust: Color = Color(0.58, 0.54, 0.46)

## Floor 13 deep accents.
@export var boardroom_black: Color = Color(0.10, 0.09, 0.10)
