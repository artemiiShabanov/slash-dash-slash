# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

slash-dash-slash is a mobile game built with Godot 4.4. The Godot project lives in the `slash-dash-slash/` subdirectory.

## Engine & Rendering

- Godot 4.4, GDScript
- Rendering method: `mobile` (optimized for mobile targets)

## Development

Open the project in Godot Editor by pointing it at `slash-dash-slash/project.godot`. Run with F5 in the editor. There is no CLI build, test, or lint pipeline configured.

## Workflow (Spec-Driven)

Three layers, each with its own cadence:

- **`GDD.md`** — vision (pillars, core loop, tone, non-goals). Read first when context is unclear.
- **`specs/<system>.md`** — per-system spec describing *what & why*. Read the relevant spec before touching a system. See `specs/README.md` for when to write one.
- **`slash-dash-slash/resources/*.tres`** — all tunables (numbers, durations, multipliers) live here as Godot Resources. Never hardcode tunables in scene scripts.

Slash commands drive the loop:

- **`/spec <name>`** — interview-driven draft into `specs/<name>.md` (status `Draft`). No code written.
- **`/build <spec>`** — implements the spec end-to-end under `slash-dash-slash/`, ticks task checkboxes, ends at status `Shipped`.
- **`/sync <spec>`** — reconciles drift after manual tuning/edits; updates the spec only (code is source of truth post-ship).

Specs describe *what & why*, code describes *how*, Resources hold *numbers*. Tuning a `.tres` should never invalidate a spec.
