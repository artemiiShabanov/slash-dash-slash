# equipment-selection-ui

**Status:** Synced 2026-05-09

## Goal

Run-start picker for sword + amulet. Chosen pair propagates to the gameplay scene via a small `RunState` autoload. Makes the M5 demo question — *does choosing equipment feel meaningful?* — actually answerable without inspector edits.

## Player-facing behavior

- New scene shown on game start. Two columns of cards: swords (left) + amulets (right), each card showing `display_name` and `description`.
- Default selections highlighted on enter; tap / click / D-pad nav to switch within a column.
- Bottom "Start Run" button transitions to the gameplay scene (`m3_combat_demo`) with the picks active.
- In gameplay, Player loads the chosen sword + amulet. Death still freezes; **F5** reloads the project, returning to the selection screen.
- Visual style: cards are built via `PaperStyle.make_paper_card` (`scripts/ui/paper_style.gd`), which applies per-node theme overrides for the paper-yellow background + ink-black typewriter text. Same paper look as the "Document" concept in `ui-style-foundation`, but via overrides (Godot strips manually-authored type-variation entries).

## Data

`RunState` autoload (`scripts/run_state.gd`, registered as `RunState` in `project.godot`):
- `chosen_sword: SwordStats` — null until selection writes; persists for the run lifetime.
- `chosen_amulet: AmuletStats` — null until selection writes.
- `func reset() -> void` — clears both, called by the selection scene on enter.

Selection scene `scenes/equipment_selection.tscn` + `scripts/equipment_selection.gd`:
- Hardcoded roster paths (inline arrays) for v1: `[letter_opener.tres, executive_katana.tres]` and `[id_lanyard.tres, field_managers_belt.tres]`.
- Per-column logic: instantiate a card per entry via `PaperStyle.make_paper_card(display_name, description, CARD_SIZE)`; track `_selected_sword_index: int` / `_selected_amulet_index: int`. `CARD_SIZE = Vector2(240, 125)`.
- Card press handler updates the index and re-applies highlight via `modulate` (active = full white, dim = ~0.55).
- "Start Run" button at bottom: writes `RunState.chosen_sword = swords[_selected_sword_index]` (loaded resource), same for amulet, then `get_tree().change_scene_to_file("res://scenes/demos/m3_combat_demo.tscn")`.

Player integration (`scripts/player.gd`):
- Equipment ladder in `_ready` (highest priority first): `RunState.chosen_sword` / `chosen_amulet` → scene-level export → default path (`DEFAULT_SWORD_PATH` / `DEFAULT_AMULET_PATH`) → class default via `.new()`.
- RunState wins unconditionally when set, so the run-start pick is honored even when player.tscn carries a debug export.

Project config:
- `project.godot` `run/main_scene` → `res://scenes/equipment_selection.tscn`.
- New autoload entry: `RunState="*res://scripts/run_state.gd"`.

## Edge cases & out-of-scope

- Gameplay scene run directly (skipping selection): Player falls back to the default `.tres` paths and runs normally — useful for direct-scene debugging.
- `RunState` cleared mid-run: Player already captured its references in `_ready`; clearing afterwards is harmless until next scene load.
- Re-entering selection mid-run: not supported; F5 / project reload is the only path back.
- Selecting an entry whose `.tres` fails to load: log push_error and skip the card; selection scene stays interactive.
- Out of scope: equipment unlocks (per-sword/amulet locked-state UI), keybind hint overlays, hover/selection animations, gem-slot preview, sword-special preview, gameplay-side "back to menu" key, save/load of last-used picks.

## Tasks

- [x] Create `scripts/run_state.gd` — autoload Node with `chosen_sword`, `chosen_amulet`, `reset()`.
- [x] Register `RunState` autoload in `project.godot`.
- [x] Create `scenes/equipment_selection.tscn` — root `Control`, two `VBoxContainer` columns under a centered `HBoxContainer`, "Start Run" Button at bottom.
- [x] Create `scripts/equipment_selection.gd` — hardcoded sword + amulet path arrays; spawns card Buttons per entry; tracks selection indices; highlights selected card; Start button writes to `RunState` and changes scene.
- [x] Update `scripts/player.gd` `_ready`: RunState picks override scene-level exports; export → default path → class default form the fallback chain.
- [x] Update `project.godot` `run/main_scene` → `res://scenes/equipment_selection.tscn`.
- [x] Smoke-test: launch project → selection screen visible with both columns; navigate via mouse, controller, and keyboard; pick `Executive Katana` + `Field Manager's Belt`; press Start; m3_combat_demo loads with red trail + 8 HP confirmed. Verify defaults (no selection / direct scene run) still work.
