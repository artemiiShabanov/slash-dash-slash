# audio-sfx-palette

**Status:** Synced 2026-05-07

## Goal

Wire the meaty combat events to sounds — every dash, slash, hit, and wall stop — routed through a single autoload. Player-state events (sword loaded, stamina exhausted) intentionally stay silent; visual feedback already communicates them, so audio would crowd the mix without adding information.

## Player-facing behavior

- A short whoosh on every dash (slash or reposition).
- A slash swing layered on top of the whoosh when the dash is actually a slash.
- A muffled "thunk" when a slash hits an enemy on the front (armored) side.
- A meaty "splat" when a slash hits on the back side.
- A sharp anticlimactic clang when a dash terminates against a wall.
- Slots populated with placeholder Kenney CC0 sounds; replace by swapping files in `assets/audio/sfx/` and re-assigning in `sfx_palette.tres`.

## Data

- Autoload: `Audio` at `scripts/audio.gd` (registered in `project.godot`).
- API: `Audio.bind_to_player(player: Node) -> void` — called from `Player._ready()`. Internally subscribes to four player signals (`dash_started`, `weapon_fired`, `hit_landed`, `wall_hit`) and dispatches to the appropriate AudioStreamPlayer. `weapon_loaded` and `stamina_changed` are intentionally not consumed here.
- Tunables — `res://resources/sfx_palette.tres` (`class_name SfxPalette`):
  - `dash_whoosh: AudioStream`
  - `slash_swing: AudioStream`
  - `hit_thunk: AudioStream` — front-armor hits.
  - `hit_splat: AudioStream` — back-armor hits.
  - `wall_clang: AudioStream`
  - `master_volume_db: float` — applied to every player (default 0).
- One `AudioStreamPlayer` child per slot under the `Audio` autoload; retriggering cuts off the previous play (acceptable for M3; polyphony is a future tweak).
- Side disambiguation comes from the `hit_landed` signal payload (`is_back_hit: bool`) — no duck-typing, no logic duplication. To enable this, two adjacent specs gain small interface changes (drift on `hit_detection` + `armor_direction`, captured at next /sync of each):
  - `take_dash_hit(damage, dash_direction) -> Dictionary` (was `void`); returns `{"final_damage": int, "is_back_hit": bool}`.
  - `hit_landed(target, final_damage, position, dash_direction, is_back_hit)` — `damage` slot now carries the post-armor amount; new trailing `is_back_hit` arg.
- Sound files live under `assets/audio/sfx/`; `README.md` lists what to drop in (Kenney / freesound / etc.).

## Edge cases & out-of-scope

- Slot has no `AudioStream` set: handler is a no-op (no warning spam).
- Same sound retriggered while still playing: previous play is cut. Worth upgrading to AudioStreamPolyphonic later if it feels choppy.
- Multiple enemies hit on one slash: each contact plays a hit sound, possibly overlapping. Acceptable.
- Out of scope: weapon-loaded chime + stamina-exhausted alarm (intentionally silent — visual feedback covers them); per-element gem crit signatures (waiting on gems); combo proc sound, mega combo chord, music bed (separate `audio-music-bed` spec); spatial audio / 2D positional, ducking, dynamic range compression, settings-menu volume sliders.

## Tasks

- [x] Create `SfxPalette` Resource (`scripts/resources/sfx_palette.gd`) with the slot fields above; create `resources/sfx_palette.tres` populated with placeholder Kenney CC0 sounds (`master_volume_db = 0`).
- [x] Create `scripts/audio.gd`: extends Node; loads `SfxPalette`; spawns one `AudioStreamPlayer` per slot as children. Implements `bind_to_player(player)` and internal handlers (`_on_dash_started`, `_on_weapon_fired`, `_on_hit_landed`, `_on_wall_hit`).
- [x] Register `Audio` autoload in `project.godot`.
- [x] Modify `dummy_enemy.gd`'s `take_dash_hit` to return `{"final_damage": int, "is_back_hit": bool}` (currently returns `void`).
- [x] Modify `player.gd`'s `_try_hit` to read the return Dictionary; emit `hit_landed(target, final_damage, position, dash_direction, is_back_hit)`. Update the `hit_landed` signal signature accordingly.
- [x] Call `Audio.bind_to_player(self)` from `Player._ready()` (one-line addition).
- [x] Create `assets/audio/sfx/README.md` listing the active event slots and recommending CC0 / royalty-free sources (Kenney, freesound.org, sfxr, etc.).
- [x] Smoke-test in Godot: scene loads without errors; signals route to handlers (verify with `print` in handlers if needed); confirm the autoload is correctly bound from the player and `is_back_hit` arrives correctly on hit signals.
