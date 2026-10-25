# Specs

One markdown file per system under `docs/specs/`. Vision lives in `docs/GDD.md`, build order in `docs/ROADMAP.md`, the work plan in `docs/plan.yaml` (each task names the specs it covers). Specs describe **what & why**; code describes **how**; `.tres` Resources hold **numbers**.

## Write a spec for

- Systems with behavior across multiple files/scenes
- Anything that touches save data
- Anything you'll forget how it works in two weeks

## Skip the spec for

- Art passes, juice, polish
- Tuning numbers — those go in `slash-dash-slash/resources/*.tres`
- One-off bug fixes

## Lifecycle

`Draft` → `/build` → `Building` → `Shipped` → (drift) → `/sync` → `Synced YYYY-MM-DD`

Use `_template.md` as the starting point. `/spec <name>` will do this for you. Once a spec ships, the matching issue gets `status: needs playtest`; decisions made along the way go to `docs/DESIGN.md`.
