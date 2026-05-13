# ui-style-foundation

**Status:** Synced 2026-05-09

## Goal

Establish the visual ground every UI surface stands on — render resolution, palette, fonts, default Theme, and the global CRT post-process — so each future component (cards, dialogue bubbles, cutscene slides, menus) inherits the retro-corporate-occult mood without re-styling from scratch. Conceptually: the entire game is *viewed through* a 1970s CRT terminal, and that's diegetic with the office's bureaucratized-magic framing.

## Player-facing behavior

- The game renders at a fixed pixel-art resolution (**640×360**) and scales to fill any screen with integer scaling for crispness. Aspect ratio is preserved with letterboxing where needed.
- A unified **CRT post-process** applies across the whole image — both world and UI — via a global shader on a topmost CanvasLayer. Effects layered in order: barrel curvature (with black bezel outside the curved region), chromatic aberration, slightly bluish phosphor tint, scanlines aligned to the internal 360-row height, signal noise, and vignette. Every scene shares one mood; nothing breaks the wash.
- The default Theme uses an **inverted CRT scheme**: dark backgrounds with bright text, `dot_matrix_green` accents on hover and borders, solid green "selected" highlights on pressed buttons. Mimics a 1970s monochrome terminal.
- All in-game UI text (HUD, menus, button labels, dialogue) uses **VT323** — a CRT/terminal font. Drives every Control by default.
- All in-world **paper documents** (memos, forms, signage, the resignation form, achievement messages styled as memos) use **Special Elite** — a typewriter font. Diegetic break: paper looks like paper *on* the monitor. Paper-styled Controls (`paper_yellow` background, `ink_black` text) are produced via the `PaperStyle` helper that applies per-node theme overrides — Godot's theme editor strips manually-authored type-variation entries on round-trip, so overrides are the durable path. The two-font / two-scheme split mirrors the lore: digital corporate vs paper bureaucracy.
- Common Godot Control types (Label, Button, Panel, RichTextLabel, LineEdit, containers, separators, scroll bars, progress bars, checkboxes, option buttons) inherit a coherent default style from the project Theme without per-scene styling.
- The mood is on by default in every new scene; opting out is possible but discouraged.

## Data

### Render configuration

Set in `project.godot`:
- `display/window/size/viewport_width = 640`
- `display/window/size/viewport_height = 360`
- `display/window/stretch/mode = "canvas_items"`
- `display/window/stretch/aspect = "keep"`
- `display/window/stretch/scale_mode = "integer"` (where supported)
- `gui/theme/custom = "res://resources/default_theme.tres"`

### Palette

`Palette` Resource (`class_name Palette`, `scripts/resources/palette.gd`). Field-per-color, all `@export Color`. Single source of truth; the Theme references it; custom drawing code reads from it.

Initial named entries (illustrative; values tuned later in `resources/palette.tres`):
- `paper_yellow` — base tint of paper / cubicle walls
- `ink_black` — primary text on paper
- `fluorescent_white` — bright UI text on dark backgrounds
- `dot_matrix_green` — terminal-style highlights
- `shadow_grey` — disabled states, secondary text
- `desk_brown` — wood paneling / executive accents
- `blood_red` — alerts, damage, the gem's dialogue
- `bone_white` — neutral panel background
- `archive_dust` — desaturated wash for Archives floor accents
- `boardroom_black` — Floor 13 deep accents

Roster expands as floors and systems demand new named slots.

### Fonts

Two fonts, both wired into the Theme:
- `font_ui` — `assets/fonts/font_ui.ttf` — **VT323** (OFL). Default font for the project Theme; drives every UI Control unless overridden.
- `font_document` — `assets/fonts/font_document.ttf` — **Special Elite** (Apache 2.0). Loaded by the `PaperStyle` helper for paper-styled surfaces.

Both fonts are free for commercial use. Replacement: drop a different `.ttf` at the same path; no theme edits needed (the `PaperStyle` helper paths point to fixed locations). See `assets/fonts/README.md` for sourcing notes.

`scripts/ui/paper_style.gd` (`class_name PaperStyle`) — static helper applying paper-yellow background + ink-black text + typewriter font overrides directly on a Control. Public API: `apply_to_button`, `apply_to_rich_text`, `apply_to_label`, `make_paper_card`. Replaces the original "Document type variation" approach.

### Default Theme

`resources/default_theme.tres`. Inverted-CRT scheme: dark surfaces with bright text, `dot_matrix_green` accents, solid green "selected" state on pressed buttons. Default font is VT323 at size 16. Comprehensive coverage:
- **Label** — `font_ui` (VT323), `font_color = fluorescent_white`
- **Button** — all four states using palette StyleBoxFlats: `boardroom_black` bg / `fluorescent_white` border (normal); slightly lighter dark / `dot_matrix_green` border (hover); solid `dot_matrix_green` bg / `ink_black` text (pressed = selected); `ink_black` bg / grey border / grey text (disabled)
- **Panel** + **PanelContainer** — `boardroom_black` background with a 1px `dot_matrix_green` border
- **RichTextLabel** — `font_ui` default with `fluorescent_white` text. Paper-styled instances apply `PaperStyle.apply_to_rich_text(label)` to swap to `font_document` (Special Elite) + `ink_black` text. Containing wrapper applies the paper background.
- **LineEdit** — `ink_black` bg, `dot_matrix_green` border + text + caret (terminal feel)
- **HBoxContainer / VBoxContainer** — `separation = 4`
- **HSeparator / VSeparator** — `shadow_grey` 1px line
- **ScrollBar (H/V)** — `ink_black` track, `dot_matrix_green` grabber
- **ProgressBar** — `ink_black` track, `blood_red` fill, `fluorescent_white` text
- **CheckBox** — `fluorescent_white` text on dark
- **OptionButton** — same StyleBoxes as Button (matching pressed/hover/normal/disabled states)
- **ColorRect / NinePatchRect** — usable as ad-hoc panels with palette colors

The Theme is registered as the project default; new Control nodes inherit it automatically. Color values are hardcoded snapshots of `palette.tres` defaults — kept in sync manually when the palette is tuned.

### CRT post-process

Global full-screen shader applied via a topmost `CanvasLayer` (mounted in an autoload so every scene gets it for free). Layered over both world and UI.

Shader (`assets/shaders/crt_post_process.gdshader`) applies, in order:
- **Barrel curvature** — UV warped around screen center; outside the curved region writes black, producing a CRT bezel
- **Chromatic aberration** — R/B channels horizontally offset from G
- **Phosphor tint** (multiplicative) — slightly bluish by default (`Color(0.92, 0.95, 1.0)`); shifts toward green/amber/red are per-floor mood territory
- **Scanlines** — alternating row darkening, aligned to the internal 360-row height (one cycle per two rows)
- **Signal noise** — procedural hash noise, animated by default; replaces the old film grain conceptually ("live signal", not aged celluloid)
- **Vignette** — radial darkening at corners

`CRTTuning` Resource (`class_name CRTTuning`, `scripts/resources/crt_tuning.gd`):
- `tint_color: Color`
- `curvature: float` (0..0.05)
- `scanline_intensity: float` (0..1)
- `chromatic_aberration: float` (0..0.01)
- `vignette_intensity: float` (0..1)
- `noise_intensity: float` (0..0.3)
- `noise_animated: bool` (default true)

Stored at `resources/crt_tuning.tres`. Per-floor variation is *not* in this spec, but the resource shape allows future per-floor overrides without code change.

The autoload lives at `scripts/crt_overlay.gd` (registered as `CRTOverlay` in `project.godot`).

**Skipped for v1:** bloom / phosphor glow (needs multi-pass; canvas_item shaders make this awkward) and the RGB triad aperture mask (too aggressive at 640×360).

## Edge cases & out-of-scope

- **High-DPI mobile screens:** the internal viewport stays 640×360; the OS handles physical-screen scaling on top of integer-scaled output. Letterboxing on extreme aspect ratios (tall mobile screens in portrait) is acceptable for v1; landscape is the assumed orientation.
- **Bezel from curvature:** with the default curvature value the corners of the canvas render as black bezel. This is intentional (CRT framing) but does eat ~5–10% of the visible canvas at corners. UI layouts must respect this — keep critical content inside a safe rectangle, not pinned to absolute corners.
- **CRT effects on UI:** intentional — the whole image is one mood. If a specific future scene needs the post-process off (e.g., an accessibility menu), it can hide the autoload's CanvasLayer locally. Not exposed as a default toggle.
- **Per-floor mood variation:** out of scope. The `CRTTuning` resource shape supports it, but the actual per-floor swapping is a future floor-content spec concern.
- **Out of scope entirely:** specific UI components (cards, dialogue bubbles, upgrade-card frames, cutscene slide layouts), animations and transitions, localization, accessibility alternates (high-contrast / colorblind modes / bezel-disable toggle), settings UI, audio, bloom / phosphor glow effect. Each lands in its own spec.

## Tasks

- [x] Set project base resolution and stretch settings in `project.godot` (640×360, canvas_items, integer scaling, aspect keep)
- [x] Create `Palette` Resource class (`scripts/resources/palette.gd`) with the named color fields above
- [x] Create `resources/palette.tres` with initial mood-correct defaults (tunable; values not load-bearing)
- [x] Install two fonts: `font_ui.ttf` = VT323 (OFL); `font_document.ttf` = Special Elite (Apache 2.0). Both under `assets/fonts/`
- [x] Create `resources/default_theme.tres` with the inverted-CRT scheme; styles all listed Control types using palette colors. Paper-styled surfaces handled via `scripts/ui/paper_style.gd` (per-node overrides) — manually-authored Document type variations don't survive Godot's theme round-trip.
- [x] Register `default_theme.tres` as `gui/theme/custom` in `project.godot`
- [x] Create `CRTTuning` Resource class (`scripts/resources/crt_tuning.gd`) and `resources/crt_tuning.tres` with mood defaults
- [x] Author `assets/shaders/crt_post_process.gdshader`: barrel curvature + chromatic aberration + phosphor tint + scanlines + signal noise + vignette, all parameterized
- [x] Create `CRTOverlay` autoload that mounts a topmost CanvasLayer with a full-screen `ColorRect` running the shader; loads `CRTTuning` to drive params
- [x] Smoke-test scene: one screen showing each themed Control type alongside a typewriter document panel; verify the CRT pass applies uniformly over both world and UI
