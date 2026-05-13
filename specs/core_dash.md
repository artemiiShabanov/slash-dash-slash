# core-dash

**Status:** Synced 2026-05-09

## Goal

Make the player's only verb feel real. A committed dash — fixed distance, fixed direction, no steering, no cancel — that travels along an authored speed curve, locks `InputSystem.dash_in_progress` so the input buffer behaves correctly, and gives enough visual feedback (sprite rotation + trail) to pass the M2 demo question: *does the dash feel good?*

## Player-facing behavior

- The player is a small character sprite at a known world position. While idle, the sprite **continuously faces the current aim direction** (driven by `InputSystem.aim_changed`) — the player can always read where their next dash will go.
- On `InputSystem.dash_requested(direction)`, the character commits to a dash:
  - The dash travels exactly `dash_distance` along `direction` over `dash_duration` seconds. Direction is locked at commit time; the sprite no longer rotates to follow aim until the dash ends.
  - The motion follows a tunable speed `Curve` resource (default: ease-out — sharp start, soft landing).
  - **No steering, no cancel.** Once the dash starts, no input can alter direction or stop it short.
  - During the dash, `InputSystem.dash_in_progress` is `true`. A new `dash_requested` is buffered by the input system (single slot, most-recent overwrite).
  - At the end of the dash, `dash_in_progress` flips to `false`. The input system auto-flushes any buffered dash, which arrives as a fresh `dash_requested` and starts the next dash with **zero gap** — chained dashes are seamless.
- A short fading **trail** follows the dash path during the motion, fading to nothing shortly after. Sells the speed and the commitment.
- Collisions with walls are *out of scope here* — the sibling `wall_collision_dash` spec will plug into the same physics body and handle the obstacle case. For now, the dash travels through anything.

## Data

### Architecture

- **Player** is a reusable scene (`scenes/player.tscn`) with a `CharacterBody2D` root running `scripts/player.gd`. Reusable so every future scene that needs the player just instantiates this.
- The script subscribes to `InputSystem.dash_requested` and `InputSystem.aim_changed` on `_ready()`. It pushes its own `global_position` into `InputSystem.player_world_position` each frame so the input system can compute mouse-relative aim.
- Dash motion advances each `_physics_process(delta)` while in the dashing state. Per-step movement uses `move_and_collide(step)` so the future `wall_collision_dash` spec can plug in by reading the `KinematicCollision2D` return value — this spec ignores it.

### State machine (player)

- `IDLE` — sprite rotates to follow `aim_changed`. On `dash_requested(dir)` → `DASHING`.
- `DASHING` — for `dash_duration` seconds, advance along `dir` per the speed curve. `InputSystem.dash_in_progress = true`. Sprite rotation locked to `dir`. Trail emits points behind the player. On time-up → `IDLE`, `dash_in_progress = false` (which flushes any buffered dash).

Implemented as an explicit enum or just a boolean `is_dashing` plus elapsed-time accumulator — whichever reads cleanest.

### Tunables — `res://resources/dash_tuning.tres` (`class_name DashTuning`)

These are **base** values. Effective per-dash values are computed from base + registered modifiers (see below).

- `base_dash_duration: float` — seconds from start to end before modifiers (default ~0.12 s)

Dash distance lives on the equipped amulet (`AmuletStats.dash_distance`, per `equipment-resource-schema`), not on DashTuning. The player uses `equipped_amulet.dash_distance` as the base in the modifier formula.
- `speed_curve: Curve` — author the speed-over-time profile. Default ease-out (1.0 at t=0 → 0.0 at t=1, decreasing). The curve's *integral* over [0,1] must produce a movement of the *effective* dash distance; the implementation normalizes by integrating the curve so authored shape and total distance stay independent.
- `idle_rotation_lerp: float` — smoothing factor (0..1) applied per-frame to the sprite's facing rotation while idle. `1.0` = snaps instantly to aim; lower = smoother but laggy. Default ~0.5.
- `trail_max_points: int` — max points in the fading trail
- `trail_fade_duration: float` — seconds for a trail point to fade to invisible
- `trail_color: Color` — reposition (non-slash) trail tint
- `trail_width: float` — reposition trail line width
- `slash_trail_color: Color` — slash trail tint (default palette `blood_red`)
- `slash_trail_width: float` — slash trail line width (wider than reposition)

### Modifiers (forward-looking)

`dash_distance` and `dash_duration` are stat-stacked from multiple sources during a run: amulet defines base reach (per GDD); gems, abilities, status effects, and per-floor mood may shift either value. The player exposes a key-based modifier registry so each owner installs and removes its contribution without others' bookkeeping:

```gdscript
# On the player (CharacterBody2D)
func set_dash_distance_modifier(key: StringName, additive: float = 0.0, multiplicative: float = 1.0) -> void
func clear_dash_distance_modifier(key: StringName) -> void

func set_dash_duration_modifier(key: StringName, additive: float = 0.0, multiplicative: float = 1.0) -> void
func clear_dash_duration_modifier(key: StringName) -> void
```

Internally each registry is a `Dictionary[StringName, {additive, multiplicative}]`. The effective value is computed as:

```
effective = (base + sum_of_additive) * product_of_multiplicative
```

Resolved at the **start of each dash** (modifiers can change between dashes, never mid-dash — fits "committed dash" pillar). Min-clamp at a small positive value so a hostile combination can't produce zero or negative distance/duration.

For this spec the registries exist with no entries; later specs (`amulet-roster`, `weapon-gem-roster`, `world-state-modifiers`) populate them.

### Player tunables — `res://resources/player.tres` (`class_name PlayerTuning`)

Body-level config that's not specific to the dash itself. Created here so future specs (combat, equipment) extend it instead of inventing their own.
- `body_radius: float` — collision radius (placeholder value for M2)
- `sprite_size: Vector2` — visual size of the placeholder sprite

(If two tuning resources feel like over-splitting, `dash_tuning.tres` can absorb body fields. Decided during build.)

### Signals (player)

- `dash_started(direction: Vector2)` — emitted at the start of a dash. Future systems (sword cooldown, hit detection) listen here.
- `dash_ended(traveled_distance: Vector2)` — emitted when a dash completes. Future systems use this to know "now is the moment to flush combo procs / start sword reload."

### Trail

`Line2D` child of the player, world-space (not transform-relative). On dash, points are appended to it each physics frame at the player's current position. The whole line fades on dash end via a tracked tween (killed if a new dash starts mid-fade so chained-dash trails aren't stomped). Trail style is picked **per dash** at `_start_dash`: if the sword fires (slash), use `slash_trail_color` + `slash_trail_width`; otherwise use `trail_color` + `trail_width`. The "was-slash" flag is captured before the weapon-fire hook flips `is_weapon_loaded`.

## Edge cases & out-of-scope

- **First-frame dash before aim has been set:** the input system already falls back to `Vector2.RIGHT` on a fresh run with no aim recorded. Player just dashes right.
- **`dash_requested` during a dash:** ignored by the player (the input system's buffer absorbs it; auto-flushes on dash end). The player never sees buffered events directly.
- **`dash_in_progress` already true at startup:** treat as false at `_ready()` regardless. Not expected in practice.
- **Fractional steps and curve integration:** the dash distance must equal the *effective* `dash_distance` (base + modifiers) even with non-trivial curves. Implementation: at dash start, snapshot effective distance and duration, integrate the curve over [0,1] once and store the normalization factor. Each frame, compute step using the normalized curve so cumulative distance is exactly `effective_dash_distance` at `t=1`. Modifier changes during the dash do not affect the in-flight motion.
- **Pathological modifier combos:** a stack of multipliers ≤ 0 or large negative additives could produce zero or negative effective distance/duration. Both effective values are clamped to a small positive minimum (e.g., 1 px and 0.01 s) so the dash always commits and completes.
- **Curve produces zero or negative areas:** clamp to a minimum (e.g., absolute value), or fall back to ease-out on invalid curves with a `push_warning`.
- **Wall collision during dash:** *out of scope here.* Player will use `move_and_collide`; the returned `KinematicCollision2D` is ignored in this spec. `wall_collision_dash` will read it and decide what to do (stop, slide, bounce, etc.).
- **Out of scope entirely:** weapon cooldown / sword loading, stamina, hit detection, gem procs, armor-direction, combat juice (sound, screen shake, hit-stop), enemy AI, particles beyond the line trail.

## Tasks

- [x] Create `DashTuning` Resource class (`scripts/resources/dash_tuning.gd`) with the fields above; create `resources/dash_tuning.tres` with sensible defaults including a default ease-out `Curve` sub-resource
- [x] ~~Create `PlayerTuning` Resource class~~ — **merged into scene-level config**: `body_radius` is the `CircleShape2D` radius on the player scene; `sprite_size` is the Polygon2D vertices on the player scene. No separate resource for v1
- [x] Build `scripts/player.gd` (extends `CharacterBody2D`):
  - subscribes to `InputSystem.dash_requested` and `aim_changed` in `_ready`
  - pushes `global_position` into `InputSystem.player_world_position` each frame
  - state machine (IDLE / DASHING) with elapsed-time accumulator
  - **modifier registries** for `dash_distance` and `dash_duration` (key → {additive, multiplicative}) with `set_*_modifier` / `clear_*_modifier` API; effective values resolved at dash start with positive-min clamp
  - per-physics-frame curve-based step using `move_and_collide` (collision result ignored for now)
  - rotates sprite toward `aim_changed` while idle (lerped by `idle_rotation_lerp`); locks rotation while dashing
  - emits `dash_started` / `dash_ended`
  - sets `InputSystem.dash_in_progress` true on dash start, false on dash end
- [x] Build `scenes/player.tscn`: `CharacterBody2D` root, placeholder visual (Polygon2D arrow shape so rotation is readable), `Line2D` for trail, `CollisionShape2D` for the body radius
- [x] Build M2 demo scene `scenes/demos/m2_dash_demo.tscn`: an arena with walls (sized for the 640×360 internal frame), a `Player` instance at center, a `Camera2D`, and an `InputFeedbackOverlay` reused from M1. Set as the project's main scene
- [x] Smoke-test verification: open the demo, confirm the player rotates smoothly toward the cursor / stick / WASD aim, that swipes/clicks/face-button-presses fire dashes that travel the configured distance with the configured curve, that chained dash inputs flow seamlessly, and that the trail fades correctly
