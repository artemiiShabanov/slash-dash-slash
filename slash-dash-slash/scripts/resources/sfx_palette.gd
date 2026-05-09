class_name SfxPalette
extends Resource

## Sound effect palette. One AudioStream slot per combat event the `Audio`
## autoload responds to. All slots default to null — the audio handler is a
## no-op for any unset slot. See `assets/audio/sfx/README.md` for sourcing.

@export var dash_whoosh: AudioStream
@export var slash_swing: AudioStream
@export var hit_thunk: AudioStream
@export var hit_splat: AudioStream
@export var wall_clang: AudioStream

## Volume offset (dB) applied to every SFX player. 0 = source-file levels.
@export var master_volume_db: float = 0.0
