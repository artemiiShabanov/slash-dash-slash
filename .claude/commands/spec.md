---
description: Draft a new system spec via interview
argument-hint: <spec-name>
---

You are drafting a new system spec named `$ARGUMENTS` for the slash-dash-slash Godot game.

## Steps

1. **Load context**: Read `GDD.md` and skim every existing file under `specs/` (excluding `_template.md` and `README.md`). Note pillars, core loop, and any related systems.

2. **Check for collision**: If `specs/$ARGUMENTS.md` already exists, stop and ask the user whether to overwrite, rename, or `/sync` the existing spec instead.

3. **Interview the user**. Use AskUserQuestion when there are clear option sets; otherwise ask in plain text. Cover:
   - **Goal** — what player experience does this enable? (1-2 sentences)
   - **Player-facing behavior** — what does the player see, feel, do?
   - **Data** — what state, signals, save fields, tunables?
   - **Edge cases** — what could break? what's explicitly out of scope?
   - **Tasks** — rough implementation steps

   Do not invent answers. If the user is vague, ask follow-ups. If something contradicts a pillar in `GDD.md`, flag it before continuing.

4. **Write the spec**: Copy `specs/_template.md` to `specs/$ARGUMENTS.md` and fill it in from the interview. Status stays `Draft`.

5. **Stop**. Do NOT write any Godot code, scenes, or resources. End by suggesting the user run `/build $ARGUMENTS` when the spec looks right.
