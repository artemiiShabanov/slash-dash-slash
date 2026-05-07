# wall-collision-dash

**Status:** Shipped

## Goal

A dash that hits a wall stops dead at the contact point and ends immediately, so corners punish bad route choices.

## Player-facing behavior

- Dashing into a wall halts the player at the collision point — no slide, no slip past.
- The dash ends right there: `dash_ended` fires with the actual traveled distance (less than the configured dash distance).
- A buffered next dash flushes as usual, so chained dashes work even from a wall stop.
- The trail visibly stops at the wall instead of continuing to the configured target.
- No cancellation by the player — wall stops are physics, not a steer.

## Data

- Signal: `wall_hit(position: Vector2, normal: Vector2)` — emitted on the player at the moment a dash is interrupted by a wall. Fires before `dash_ended`.
- No new tunables. No new resources.
- Implementation: `_advance_dash()` reads the `KinematicCollision2D` returned by `move_and_collide` and triggers an early end when non-null.

## Edge cases & out-of-scope

- Zero-length step that still reports a collision (immediate flush wall): treated as a wall hit at current position; dash ends with traveled = `Vector2.ZERO`.
- Multiple collisions in a single physics frame: the first one wins; subsequent ones ignored.
- Wall encountered exactly on the final step: dash ends one frame earlier than time-up; not a problem.
- Out of scope: hit-stop, screen shake, sound, particles, damage on wall hit, slide-along behavior, bounce behavior, "magnetism" near wall edges.

## Tasks

- [x] Add `signal wall_hit(position: Vector2, normal: Vector2)` to `scripts/player.gd`.
- [x] In `_advance_dash`, capture the `move_and_collide` return; if non-null, emit `wall_hit(collision.get_position(), collision.get_normal())` and call `_end_dash()` to terminate early.
- [x] Verify the trail stops at the wall and chained dashes still flow after a wall stop.
- [x] Smoke-test: dash into each wall edge of `m2_dash_demo.tscn`; player snaps to the wall, signal fires, trail terminates, and a queued chained dash starts cleanly. *(Required adding `StaticBody2D` + `CollisionPolygon2D` to each wall in the demo scene — they were visual-only `Polygon2D` previously.)*
