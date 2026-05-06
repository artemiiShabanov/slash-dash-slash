---
description: Implement a spec end-to-end
argument-hint: <spec-name>
---

You are implementing the spec `specs/$ARGUMENTS.md` in the slash-dash-slash Godot 4.4 project.

## Steps

1. **Load context**: Read `specs/$ARGUMENTS.md` and `GDD.md`. If the spec file is missing, stop and tell the user.

2. **Check status**:
   - If `Draft` or `Building` → proceed.
   - If `Shipped` or `Synced ...` → STOP. Tell the user the spec is shipped; suggest `/sync $ARGUMENTS` for drift, or editing the spec back to `Draft` if they're intentionally rebuilding.

3. **Set status to `Building`** in the spec file.

4. **Implement, task by task**:
   - Code goes under `slash-dash-slash/scripts/` and scenes under `slash-dash-slash/scenes/`. Create the folders if they don't exist.
   - **Tunables (numbers, durations, speeds, multipliers) MUST go in a Resource** at `slash-dash-slash/resources/$ARGUMENTS.tres`, defined by a Resource script (`class_name`) under `slash-dash-slash/scripts/resources/`. Never hardcode tunables in scene scripts. If the system has no tunables, skip this.
   - GDScript conventions: `snake_case` for funcs/vars, `PascalCase` for classes/nodes, `@export` for editor-tunable fields, signals declared at top of script.
   - Tick each `- [ ]` to `- [x]` in the spec as the corresponding task lands.

5. **Finish**:
   - Set status to `Shipped`.
   - List the files you created/modified.
   - Tell the user to open Godot and run the relevant scene to verify.

## Constraints

- Do not edit `GDD.md` or other specs.
- Do not add features beyond the spec's task list — if you discover a gap, stop and ask whether to update the spec first.
- Do not create tests, CI, or build scripts unless the spec asks for them.
