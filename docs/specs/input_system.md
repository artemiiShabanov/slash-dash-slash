# input-system

**Status:** Synced 2026-05-06

## Goal

Make every dash feel intentional and platform-native: one-thumb touch, controller, mouse+keyboard, and keyboard-only all honor the "committed dash" pillar with no platform feeling secondary. Hot-swap between sources without breaking flow.

## Player-facing behavior

- **Touch (one-thumb):** a directional swipe anywhere on the screen commits a dash in that direction. Dash distance is fixed (per GDD); swipe length affects direction only, never magnitude. A subtle pixel-art trail follows the finger to confirm the gesture registered.
- **Controller:** left stick continuously aims; any of the four face buttons (A, B, X, Y / Cross, Circle, Square, Triangle) commits the dash in the stick's current direction.
- **Mouse + keyboard:** mouse cursor sets aim direction relative to the player; left-click commits the dash. A faint aim-line preview shows the planned direction.
- **Keyboard-only:** WASD or arrow keys aim in 8 directions (continuous polling, hold for diagonals); **Space** commits the dash. The aim-line preview is shown the same as in M+KB.
- **Continuous aim feedback:** every source emits a continuous aim direction during input — the touch swipe-in-progress vector, the controller stick direction, the mouse-relative-to-player vector, the WASD/arrow vector. UI and character sprite consume this to rotate (aim line, sprite facing). All non-touch sources show the aim line; touch shows the swipe trail instead. The committed dash uses the most recent non-zero aim direction at the moment of commit, so an input is never silently dropped.
- **Hot-swap:** the first input from a different source switches the active scheme on the fly. UI glyphs (where shown) update accordingly. No pause, no confirmation.
- **Mid-dash input:** a dash input during an in-progress dash queues exactly one buffered dash, which auto-commits when the current dash ends. Additional inputs overwrite the buffer (most recent wins).
- **Pause:** Start/Options on controller, Esc on M+KB or keyboard-only. Touch pause UI is deferred to a future UI-pass spec — touch users currently rely on the OS gesture or a separate spec to handle in-game pause. Cutscene advance, upgrade-card UI nav, and settings UI are scoped out.

## Data

`InputSystem` singleton (autoload). Emits a single `dash_requested(direction: Vector2)` signal regardless of source — combat code listens to this without knowing the platform.

**Signals:**
- `dash_requested(direction: Vector2)` — discrete commit
- `aim_changed(direction: Vector2)` — continuous; fires whenever the active source updates its aim direction (non-zero only)
- `pause_pressed()`
- `input_source_changed(source: int)` — payload is an `InputSource` enum value (typed as int in the signal sig)

**State (publicly readable; `dash_in_progress` and `player_world_position` are publicly settable):**
- `current_source: InputSource` — one of `TOUCH | CONTROLLER | MOUSE_KEYBOARD | KEYBOARD`
- `current_aim_direction: Vector2` — most recent non-zero aim from the active source; persisted across moments of zero magnitude. Used as the dash direction at commit time.
- `buffered_dash_direction: Vector2 | null`
- `dash_in_progress: bool` — set by gameplay code (the `dash` system) to indicate whether a dash is currently animating. Flipping this from `true` to `false` flushes the buffered dash by emitting `dash_requested`.
- `player_world_position: Vector2` — set each frame by the player so the input system can compute mouse-relative aim direction.

**Input tunables — `res://resources/input_system.tres` (`class_name InputTuning`):**
- `swipe_min_distance` (px)
- `swipe_max_duration` (s) — max gesture time before classified as drag (ignored)
- `controller_stick_deadzone` (0–1)

**Feedback overlay tunables — `res://resources/input_feedback.tres` (`class_name FeedbackTuning`):**
- `swipe_trail_duration` (s)
- `aim_line_length` (px)

The two resources are owned by separate concerns: `InputTuning` for input logic, `FeedbackTuning` for visual feedback. The overlay loads its own tuning; the input system does not depend on it.

## Edge cases & out-of-scope

- **Multi-touch / palm rejection:** the first touch that starts a swipe owns the gesture; additional touches ignored until that finger lifts.
- **Controller disconnect mid-dash:** the in-progress dash completes; subsequent inputs default to whichever source produces the next event. No error UI here.
- **Cancelled swipes:** swipes that don't reach `swipe_min_distance` before lift-off don't fire a dash. Trail draws faintly anyway, communicating "registered but rejected."
- **Zero-magnitude aim at commit:** if the stick is in deadzone or the cursor sits on the player at the instant of commit, the dash uses `current_aim_direction` (last known non-zero aim) — never silently dropped. On first frame of a fresh run with no aim yet recorded, dash falls back to "right" (Vector2.RIGHT) as an arbitrary safe default.
- **Out of scope:** cutscene advance/skip, upgrade-card UI nav, equipment-selection UI, settings, key rebinding, accessibility alternates — each gets its own spec.

## Tasks

- [x] Create `InputTuning` Resource class and `res://resources/input_system.tres` with defaults
- [x] Build `InputSystem` autoload with all four signals above
- [x] Track `current_aim_direction` from active source; emit `aim_changed` on every non-zero update
- [x] Touch swipe detection (first-touch ownership, direction at lift, min-distance + max-duration enforcement)
- [x] Controller stick + face-button handling (any of A/B/X/Y commits; deadzone for noise filtering only; commit uses last-known aim if in deadzone at press)
- [x] Mouse aim + left-click handling (commit uses last-known aim if cursor is on player)
- [x] Keyboard-only handling: 8-dir aim from WASD/arrows (continuous polling), Space commits
- [x] Seamless hot-swap (last-input-wins per source, emit `input_source_changed`)
- [x] Mid-dash queue (single-slot, most-recent overwrite)
- [x] Pause input on controller (Start), M+KB (Esc), and keyboard-only (Esc) — emits `pause_pressed`. Touch pause UI deferred to a future UI-pass spec.
- [x] Visual feedback: touch swipe trail; aim-line preview for all non-touch sources (M+KB, controller, keyboard-only)
- [x] M1 demo scene: empty room with walls; a placeholder player whose only behavior is logging `dash_requested` events so the spec is smoke-testable independent of `dash` being built
