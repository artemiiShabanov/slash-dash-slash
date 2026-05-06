# Fonts

| File | Role | Font | License |
|---|---|---|---|
| `font_ui.ttf` | Default font for all in-game UI (drives the Theme) | **VT323** by The VT323 Project Authors | OFL — free for commercial use |
| `font_document.ttf` | Paper documents, memos, the resignation form (RichTextLabel with `theme_type_variation = "Document"`) | **Special Elite** by Astigmatic | Apache 2.0 — free for commercial use |

Both wired up in `resources/default_theme.tres`.

## Swapping fonts

Drop a replacement file with the same name (`font_ui.ttf` or `font_document.ttf`) and Godot picks it up automatically — no theme edits needed. Use `.fnt` if you ever want a true bitmap pixel font; rename the corresponding entry in `default_theme.tres` if so.

## Re-fetching from source

```sh
curl -sSL -o font_ui.ttf       https://github.com/google/fonts/raw/main/ofl/vt323/VT323-Regular.ttf
curl -sSL -o font_document.ttf https://github.com/google/fonts/raw/main/apache/specialelite/SpecialElite-Regular.ttf
```
