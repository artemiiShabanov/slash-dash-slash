# <System Name>

**Status:** Draft

<!--
Keep specs short and scannable. A reader should be able to absorb the whole
thing in under a minute. Prose explanations belong in code comments, not specs.

Brevity guidelines (soft, not enforced):
- Goal: 1-2 sentences.
- Behavior: bullet list, not prose. Skip pillar restatements — the GDD lives next door.
- Data: signal signatures, state, tunable paths/fields. Signature lines, not paragraphs.
- Edges: bullets, one line each.
- Tasks: one-liner per checkbox. Sub-bullets only when a task genuinely needs them.
- Total: aim ~40-80 lines. If you're past 100, cut.
-->

## Goal

One or two sentences. The player experience this enables.

## Player-facing behavior

- Bullet list of what the player sees, feels, does. Concrete, terse.

## Data

- Signals: `signal_name(arg: Type)` — short description
- State: `field_name: Type` — short description
- Tunables: `res://resources/<name>.tres` (`class_name`) — list fields without prose

## Edge cases & out-of-scope

- Edge case, one line each.
- Out-of-scope items follow the same format.

## Tasks

- [ ] One-liner per task. No sub-bullets unless genuinely needed.
