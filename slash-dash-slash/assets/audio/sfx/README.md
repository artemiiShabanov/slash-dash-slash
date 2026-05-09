# SFX

Five slots are populated. Replace any file with a better-sounding one and Godot will pick it up automatically — names are stable.

## Current picks

| Slot | File | Source |
|---|---|---|
| `dash_whoosh` | `sfx_dash_whoosh.ogg` | Kenney **RPG Audio** — `bookFlip2.ogg` (paper rustle, leans into the office vibe) |
| `slash_swing` | `sfx_slash_swing.ogg` | Kenney **RPG Audio** — `knifeSlice.ogg` |
| `hit_thunk` | `sfx_hit_thunk.ogg` | Kenney **Impact Sounds** — `impactSoft_medium_002.ogg` (deflected, muffled) |
| `hit_splat` | `sfx_hit_splat.ogg` | Kenney **Impact Sounds** — `impactPunch_heavy_002.ogg` (full-damage, meaty) |
| `wall_clang` | `sfx_wall_clang.ogg` | Kenney **Impact Sounds** — `impactMetal_medium_002.ogg` |

Kenney sounds are CC0 (see `KENNEY_LICENSE.txt`).

## Intentionally not audio-driven

`weapon_loaded` and `stamina_exhausted` events are silent — visual feedback (body tint when loaded, stamina pip drain) communicates them already. Audio for these would crowd the mix without adding information.

## Swapping sounds

To replace any slot:
1. Drop a new `.wav` or `.ogg` into this folder.
2. Open `resources/sfx_palette.tres` in Godot and re-assign the slot to the new file (or rename the new file to match the existing slot filename).

## Sources for new picks

- **Kenney** — https://kenney.nl/assets — large game-SFX packs, CC0
- **freesound.org** — community library, filter by CC0
- **sfxr / bfxr / chiptone** — generate retro 8-bit sounds in seconds

## Mixing notes

Mobile speakers will flatten everything — keep transients sharp, avoid muddy low end. Test on a phone, not headphones.
