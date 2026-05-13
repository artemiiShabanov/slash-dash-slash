# weapon-cooldown-stamina

**Status:** Synced 2026-05-09

## Goal

Gate the sword behind a short cooldown and a small stamina counter so each dash is either a hit or a deliberate reposition, and rapid hits are capped by stamina.

## Player-facing behavior

- The sword has two visible states: **loaded** (next dash is a slash) and **reloading** (next dash is just movement).
- A dash with a loaded sword fires the weapon: stamina drops by 1, cooldown timer resets, sword goes reloading. Whether the dash actually contacts an enemy is hit-detection's job.
- A dash with an unloaded sword is a non-hit reposition. No stamina drain.
- Sword becomes loaded again as soon as the cooldown elapses **and** stamina ≥ 1.
- Stamina regenerates one point every `stamina_regen_interval` seconds, up to `max_stamina`. Regen runs continuously, even mid-cooldown.
- Visual: a row of `max_stamina` small circles floats above the player. Slashing immediately empties one circle; regen ticks fade them back in. While the sword is loaded the player sprite shifts to a placeholder loaded tint (real "loaded" sprite animation deferred to art).
- Audio: a `weapon_loaded` signal fires when the sword becomes ready — `audio-sfx-palette` will play the loaded chime here.

## Data

Tunables now live on the equipped sword (per `equipment-resource-schema`); the player reads them via `equipped_sword.*`.

- Signal: `weapon_fired(direction: Vector2)` — emitted from `_start_dash` when sword is loaded; hit-detection listens.
- Signal: `weapon_loaded()` — emitted when sword transitions reloading → loaded.
- Signal: `weapon_unloaded()` — emitted when sword transitions loaded → reloading.
- Signal: `stamina_changed(current: int, max: int)` — emitted on any change; the stamina-circles UI listens.
- State: `is_weapon_loaded: bool` — current ready flag.
- State: `stamina: int` — `0..equipped_sword.max_stamina`.
- State: `_cooldown_remaining: float` — seconds left in current cooldown.
- State: `_regen_accumulator: float` — fractional seconds toward next stamina tick.
- Tunables (sourced from `SwordStats`; see `equipment-resource-schema`):
  - `cooldown_duration: float` — seconds per fire.
  - `max_stamina: int` — consecutive-slash cap.
  - `stamina_regen_interval: float` — seconds per stamina point.
  - `loaded_tint_color: Color` — placeholder sprite modulate while loaded.
- Stamina UI scene: `scenes/ui/stamina_pips.tscn` — a `Node2D` of `max_stamina` small circles drawn via `_draw`, positioned just above the player by an offset; subscribes to `stamina_changed`.

## Edge cases & out-of-scope

- Dash with stamina = 0 but cooldown elapsed: still a non-hit dash; no fire.
- Tuning change at runtime (e.g., live editor tweak of `max_stamina`): clamp current stamina to new max, re-emit `stamina_changed`.
- Modifier system (gems / amulets buffing cooldown or stamina): not in scope here. Same pattern as `core_dash` modifier registries can be added later.
- Sword identity / equipped-sword-resource: handled by `equipment-resource-schema` (since shipped).
- Real "loaded" sprite animation: deferred until the player gets a real sprite sheet; placeholder tint stands in.
- Audio playback: `audio-sfx-palette` listens to the signals and plays. Not done here.
- Hit detection, hit feedback, gem procs, armor: separate specs.

## Tasks

- [x] Create `WeaponTuning` Resource (`scripts/resources/weapon_tuning.gd`) and `resources/weapon_tuning.tres` with defaults above.
- [x] Add weapon state + tuning to `scripts/player.gd`: `is_weapon_loaded`, `stamina`, cooldown timer, regen accumulator, the four signals.
- [x] In `_start_dash`: if loaded, consume stamina, reset cooldown, flip `is_weapon_loaded` false, emit `weapon_fired(direction)` and `weapon_unloaded`. If not loaded, dash proceeds as a reposition.
- [x] In `_physics_process` (or a dedicated `_tick_weapon(delta)`): tick down cooldown; tick regen; on transition to loaded, emit `weapon_loaded`.
- [x] Apply `loaded_tint_color` to the player Polygon2D `modulate` while loaded; restore base tint while reloading.
- [x] Build `scenes/ui/stamina_pips.tscn`: Node2D drawing N circles, fade-in on regen, instant clear on drain. Tunable offset above the player.
- [x] Instance the pips under the player scene with an offset; verify the row tracks the player and updates on `stamina_changed`.
- [x] Smoke-test in `m2_dash_demo`: spam dashes, observe that the first 3 hit (if walls don't block), the 4th is a non-hit reposition, and the row of pips refills over time.
