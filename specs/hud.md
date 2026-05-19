# hud

**Status:** Shipped

## Goal

Diegetic live stats (hearts above the player, mirroring stamina pips) and a CRT-terminal-styled equipment readout in the top-left — sword / amulet / gem icons inside dot-matrix-green slot frames, with empty slots visibly showing the unused capacity of the equipped sword.

## Player-facing behavior

- **Heart pips** float above the player, just above the stamina row. Drain on damage instant, refill on heal fades in — mirrors stamina cadence.
- **Status-icon strip** below the stamina row. Reserved render surface; nothing shows today because no enemy ability applies status to the player yet.
- **Equipment chip** (top-left CanvasLayer): three icon groups separated by short vertical dividers, all framed in the project's terminal theme (`boardroom_black` bg, `dot_matrix_green` 1px borders, VT323 labels where needed):
  - **Equipment row:** sword icon + amulet icon.
  - **Weapon gem slots:** `equipped_sword.gem_slot_count` slot frames in a row; the first N filled with gem icons (one per equipped gem); the rest visibly empty (frame only, dimmed inner). At a glance: how many gems you have vs how many you could.
  - **Amulet gem slot:** single slot framed identically; filled with the amulet gem's icon when equipped.

## Data

### Player drift

- New `signal health_changed(current: int, max: int)` — mirrors `stamina_changed`. Emitted on every health mutation; initial emit deferred from `_ready` so children connect first.
- New `_set_health(value: int, source: Node = null)` — clamps to `equipped_amulet.max_health`, sets `health`, emits `health_changed`, emits `damaged(prev - new, source)` (heals stay negative, debug damage_number_spawner unchanged).
- `take_damage` routes through `_set_health`.

### Drift on `equipment`

- `SwordStats.icon: Texture2D` (default null).
- `AmuletStats.icon: Texture2D` (default null).
- Existing rosters left null today; placeholder procedural rendering covers (see fallback below). Art pass adds real PNGs without code churn.

### Drift on `gems`

- `Element` gains `static func icon(kind: Kind) -> Texture2D` — returns the per-element icon (preloaded from `assets/icons/elements/<kind_name>.png` if present; null otherwise).
- `AmuletGem.icon: Texture2D` (default null).
- Vampiric / HealPickup route through `Player._set_health(...)` instead of mutating `player.health` directly.

### Icon fallback

When an icon is null, the HUD draws a placeholder: filled rect in the entity's signature color (per-element `Element.color(kind)` for gems; `Palette.dot_matrix_green` for sword; `Palette.bone_white` for amulet) with the first character of `display_name` in VT323 centered on top. Same square dimensions as real icons so layout doesn't reflow when art lands.

### HudTuning

`scripts/resources/hud_tuning.gd` (`class_name HudTuning`) at `res://resources/hud_tuning.tres`:
- `health_offset: Vector2` — heart row offset above stamina pips (default `Vector2(0, -8)`).
- `status_offset: Vector2` — status strip offset below stamina pips (default `Vector2(0, 8)`).
- `pip_spacing: float` — px between heart centers (default 5.0).
- `pip_fade_duration: float` — pip refill fade (default 0.2).
- `heart_filled_color: Color` — palette `blood_red` by default.
- `heart_drained_color: Color` — desaturated red (default `Color(0.30, 0.18, 0.20, 0.4)`).
- `icon_size: int` — equipment-chip icon px (default 14, fits 640×360).
- `slot_frame_color: Color` — palette `dot_matrix_green` by default.
- `slot_empty_alpha: float` — alpha multiplier on empty slot inner (default 0.25).
- `chip_padding: Vector2` — top-left chip margin (default `Vector2(6, 6)`).
- `chip_separator_width: int` — divider between icon groups (default 4).

### Scenes / scripts

`scripts/ui/health_pips.gd` + `scenes/ui/health_pips.tscn` — Node2D mirror of StaminaPips. Pip count = `equipped_amulet.max_health`. Subscribes to `player.health_changed`; instant drain, faded refill via `pip_fade_duration`. Hearts rendered as small filled circles in `heart_filled_color` (placeholder shape; real heart sprite swappable later by changing one constant or texture).

`scripts/ui/player_status_icons.gd` + `scenes/ui/player_status_icons.tscn` — Node2D, child of player at `status_offset`. Exposes `refresh()`; reads `player._burns / _slows / _stuns / _vulns` once a future spec installs those arrays on the Player. Renders nothing today.

`scripts/ui/equipment_chip.gd` + `scenes/ui/equipment_chip.tscn` — `CanvasLayer` root + `PanelContainer` styled by the default theme. `populate(player: Node)` called from `_ready` of the demo scene. Children built procedurally:
- HBox row containing three sub-HBoxes separated by `VSeparator`:
  1. Sword icon (16-px slot frame, filled).
  2. Amulet icon (16-px slot frame, filled).
  3. Weapon gem slots: `equipped_sword.gem_slot_count` frames; first `min(slot_count, equipped_weapon_gems.size())` filled with `Element.icon(gem.element)` (or fallback); remaining frames empty (dimmed inner).
  4. Amulet gem slot: one frame, filled with `equipped_amulet_gem.icon` (or fallback) when non-null; empty frame when null.
- Reserved one-shot connection to `player.equipment_changed` (no producer today) so a future selection-UI swap reflects.

Each "slot frame" is a tiny custom Control subclass (or `PanelContainer` with a per-instance StyleBoxFlat) that draws a `slot_frame_color` 1px border on `boardroom_black`, with an inner TextureRect or fallback ColorRect+Label. Empty slots dim the inner by `slot_empty_alpha`.

### Demo wiring

- `scenes/player.tscn` adds `HealthPips` + `PlayerStatusIcons` children.
- `scenes/demos/m3_combat_demo.tscn` adds an `EquipmentChip` CanvasLayer; `_ready` calls `populate(Player)`.

## Edge cases & out-of-scope

- `equipped_amulet == null` at heart-pip ready: pip count falls back to 1 with `push_warning`.
- Heart row width with high max_health (e.g. 8 HP belt): row stays inline; >10 falls back to "❤ × N" text (future tuning, noted not coded).
- `equipped_sword.gem_slot_count = 0`: weapon gem group renders an empty container, not a stray label.
- More equipped gems than slots (debug_loadout has 6 vs katana's 1): chip renders the slot count *frames*; extras don't display. Selection UI will enforce.
- Equipment chip mid-run refresh: no `equipment_changed` producer yet; the connection is reserved.
- Status icons today render nothing (no producers).
- Icons null today: fallback placeholder (color + first letter); swap to real PNG by setting `icon` on the relevant `.tres` — no scene edits required.
- CRT post-process applies on top of the chip uniformly (per `ui-style-foundation`); chip styling assumes the wash and uses high-contrast palette colors to stay legible after scanlines + chromatic aberration.
- HP at 0: hearts go fully drained; death freeze + screen handled by future spec.
- Out of scope: real icon art (placeholder fallback suffices), floor / quest indicator, sword loaded vs reloading state on the chip, gem upgrade level dots, hot-swap animations, `healed` signal proper, `equipment_changed` producer (waits on a future hot-swap path), bezel-safe-area guarantees beyond the existing 6-px padding.

## Tasks

- [x] `Player`: add `signal health_changed(current, max)`, `_set_health(value, source)`; route `take_damage` and update `VampiricAmuletGem` + `HealPickup` to call it.
- [x] `SwordStats` + `AmuletStats`: add `icon: Texture2D` field (default null).
- [x] `AmuletGem`: add `icon: Texture2D` field (default null).
- [x] `Element`: add `static func icon(kind) -> Texture2D` returning null today; future drop-in for `assets/icons/elements/<kind_name>.png`.
- [x] `HudTuning` Resource + `resources/hud_tuning.tres` with defaults above.
- [x] `HealthPips` script + scene, mirror of `StaminaPips`; subscribe to `health_changed`.
- [x] `PlayerStatusIcons` script + scene; expose `refresh()`; render nothing today.
- [x] `SlotFrame` reusable Control (`scripts/ui/slot_frame.gd` + scene): styled box with optional Texture2D or fallback color+letter; `set_filled(icon, fallback_color, fallback_letter)` / `set_empty()` API.
- [x] `EquipmentChip` script + scene: CanvasLayer + PanelContainer; `populate(player)` builds the four icon groups using `SlotFrame` instances.
- [x] Add `HealthPips` + `PlayerStatusIcons` to `scenes/player.tscn`.
- [x] Add `EquipmentChip` to `scenes/demos/m3_combat_demo.tscn`; populate on `_ready`.
- [x] Smoke-test: hearts drain on dummy hits; refill via cooler pickup or vampiric kill. Equipment chip shows sword + amulet placeholder icons; weapon gem row shows 1 filled slot (katana) or up to `gem_slot_count` frames for other swords; amulet gem slot shows the Water Cooler Token placeholder; all framed in dot-matrix-green on dark background, legible through the CRT post.
