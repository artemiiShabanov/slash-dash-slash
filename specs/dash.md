# dash

**Status:** Shipped (consolidated 2026-05-19, supersedes `core-dash`, `wall-collision-dash`, `weapon-cooldown-stamina`)

## Goal

The dash is the single player verb: committed, fixed distance, fixed direction, no steering. Wraps wall termination, weapon loaded/reloading state, and the stamina cap that gates consecutive slashes.

## Player-facing behavior

- Idle: sprite continuously rotates toward `InputSystem.aim_changed`.
- `InputSystem.dash_requested(direction)` commits a dash: distance + direction locked at start, motion follows an authored speed `Curve`, no cancel, no steer.
- During the dash, `InputSystem.dash_in_progress = true`; further `dash_requested` events are buffered (single slot, most-recent overwrite) and auto-flush on dash end so chained dashes have zero gap.
- A short fading **trail** marks the dash path. Slash dashes use a wider, redder trail; reposition dashes use a thinner default tint.
- Dashing into a wall halts the player at the contact point and ends the dash early. Other termination paths (interactable with `stops_dash=true`, see `interaction-system`) reuse the same event.
- Sword has two visible states: **loaded** (next dash is a slash) and **reloading** (next dash is reposition only). A loaded dash drains 1 stamina, resets the cooldown, sets reloading. An unloaded dash is just movement; no stamina drain.
- Stamina regenerates one point every `stamina_regen_interval` seconds up to `equipped_sword.max_stamina`. Regen runs continuously, even mid-cooldown. A row of pip circles above the player visualizes current stamina.
- Sword becomes loaded again as soon as cooldown elapses AND stamina ≥ 1.

## Data

`scripts/player.gd` (`CharacterBody2D` root at `scenes/player.tscn`) subscribes to `InputSystem.dash_requested` + `aim_changed` in `_ready`, pushes `global_position` into `InputSystem.player_world_position` each frame, and runs the dash + weapon state machines.

Signals (player):
- `dash_started(direction: Vector2)` — at the start of a dash.
- `dash_ended(traveled: Vector2)` — at termination (time-up, wall, or stops_dash interactable).
- `wall_hit(position: Vector2, normal: Vector2)` — fires before `dash_ended` when a wall (or stops_dash interactable, with zero normal) terminates the dash. Audio + future juice systems consume.
- `weapon_fired(direction: Vector2)` — emitted in `_start_dash` when the sword is loaded; `combat-hit-resolution` + `gems` proc roll listen.
- `weapon_loaded()` / `weapon_unloaded()` — sword state transitions.
- `stamina_changed(current: int, max: int)` — emitted on any stamina change; pips UI listens.

State (player):
- `is_dashing: bool` + elapsed-time accumulator (DASHING ↔ IDLE).
- `is_weapon_loaded: bool`, `stamina: int`, `_cooldown_remaining: float`, `_regen_accumulator: float`.

Tunables — `res://resources/dash_tuning.tres` (`class_name DashTuning`):
- `base_dash_duration: float` — seconds; default ~0.12.
- `speed_curve: Curve` — speed-over-time profile (default ease-out). The implementation integrates the curve once at dash start and normalizes so cumulative motion equals the effective distance at t=1, independent of curve shape.
- `idle_rotation_lerp: float` — facing smoothing factor (0..1).
- `trail_max_points`, `trail_fade_duration`, `trail_color`, `trail_width`, `slash_trail_color`, `slash_trail_width`.

Tunables sourced per-run from the equipped sword (see `equipment`): `cooldown_duration`, `max_stamina`, `stamina_regen_interval`, `loaded_tint_color`. Tunables sourced from the equipped amulet: `dash_distance`.

Modifier registries on the player (key-indexed, additive + multiplicative):
- `set_dash_distance_modifier(key, additive, multiplicative)` / `clear_dash_distance_modifier(key)`
- `set_dash_duration_modifier(key, additive, multiplicative)` / `clear_dash_duration_modifier(key)`
- Effective value: `(base + Σ additive) × Π multiplicative`, resolved at dash start, clamped to a small positive minimum. Modifier changes mid-dash do not affect in-flight motion.

Movement: `_advance_dash` per physics frame uses `move_and_collide(step)`. A non-null `KinematicCollision2D` triggers `wall_hit.emit(pos, normal)` then `_end_dash()`. Interactable termination from `_on_interact_area_entered` reuses the same `wall_hit` + `_end_dash` sequence (deferred via `call_deferred` because it runs inside Godot's physics flush).

Trail: world-space `Line2D` child of the player. Slash vs reposition palette picked at `_start_dash` before the weapon-fire hook flips `is_weapon_loaded`.

Stamina pips: `scenes/ui/stamina_pips.tscn` — Node2D drawing N circles above the player, subscribed to `stamina_changed`. Drain is instant, refill fades in.

## Edge cases & out-of-scope

- First-frame dash with no aim set: input system defaults to `Vector2.RIGHT`.
- `dash_requested` during a dash: buffered by input system, never sees the player directly.
- Pathological modifier stacks (≤ 0 effective): clamped to a small positive value so the dash always commits and completes.
- Curve with negative area: clamp to absolute value or fall back to ease-out with a `push_warning`.
- Multiple wall collisions in one physics frame: first wins.
- Dash with stamina = 0 and cooldown elapsed: still a non-hit reposition.
- Tuning swap at runtime (live editor tweak of `max_stamina`): clamp current stamina and re-emit `stamina_changed`.
- `wall_hit` currently mixes wall-collision and interactable termination. Acceptable until a downstream consumer needs to distinguish them.
- Out of scope: hit detection / damage / armor (see `combat-hit-resolution`), gem procs (see `gems`), enemy AI (see `enemy`), screen shake / hit-stop / particles beyond the trail line.
