class_name InteractionTuning
extends Resource

## Tunables shared by every `Pickup` subclass. Stored at
## `res://resources/interaction_tuning.tres`. Per-pickup payloads (heal_amount,
## etc.) live on the pickup Resource subclasses themselves.

## Pixels at which a pickup starts seeking the player. Once seeking, the
## pickup never gives up (no rescind), so this is effectively the activation
## ring.
@export var attract_radius: float = 60.0

## Position lerp coefficient per second. Higher = snappier suction. Clamped
## per-frame to avoid overshoot at extreme frame rates.
@export var lerp_factor: float = 8.0

## Seconds a freshly-spawned pickup ignores the attract ring. Lets drops
## visibly scatter from their source before they start flying at the player.
## Player can still walk into them during the delay — only auto-seek is gated.
@export var seek_delay: float = 0.1

## Per-second velocity decay applied to pre-seek scatter motion. Higher =
## drops stop sooner. Tuned alongside the scatter_speed range on each
## interactable that spawns drops.
@export var scatter_friction: float = 4.0
