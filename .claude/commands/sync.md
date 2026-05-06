---
description: Close drift between spec and shipped code
argument-hint: <spec-name>
---

You are reconciling drift between `specs/$ARGUMENTS.md` and the shipped code in slash-dash-slash.

## Principle

Code is the source of truth post-ship. The spec gets updated to match reality, NOT the other way around. If reality is wrong, that's a separate `/build` cycle, not a `/sync`.

## Steps

1. **Read the spec**: `specs/$ARGUMENTS.md`. If missing, stop.

2. **Find the implementation**: Search `slash-dash-slash/scripts/`, `slash-dash-slash/scenes/`, and `slash-dash-slash/resources/` for files related to this spec (by name, by referenced classes, by signal names mentioned in the spec).

3. **Diff**:
   - **Behaviors in code that the spec doesn't describe** → candidate spec additions.
   - **Behaviors in the spec that aren't in the code** → candidate spec removals (or flag as a real bug if the user expected them shipped).
   - **Tunable values** → don't list specific numbers in the spec; just confirm the `.tres` reference is correct.
   - **Data shape changes** (signal renames, new save fields) → must update spec.

4. **Report findings to the user** before editing. List drift as a bulleted diff. Ask which items to apply.

5. **Apply approved edits** to the spec only. Set status to `Synced YYYY-MM-DD` using today's date.

## Constraints

- Do not modify any code or resources.
- Do not modify other specs or `GDD.md`.
- If you find drift that suggests a pillar violation (per `GDD.md`), flag it but don't act.
