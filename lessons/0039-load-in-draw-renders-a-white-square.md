---
id: 0039
title: A texture load()-ed inside _draw() showed as a white square in the first frames
area: ui
severity: minor
status: encoded
---

**What happened:** The result popup's stars were drawn with `draw_texture_rect(load("res://...star.png"), ...)` inside `_draw()` and appeared as solid white squares in the capture; the same texture through a `preload` constant drew correctly.
**Root cause:** loading in the draw path returned a texture that was not ready for the renderer in that frame.
**Rule:** textures used by `_draw()` are `preload` constants (or loaded once in `_ready`), never `load()` inside the draw call.
**Encoded in:** `slide-buddies/ui/star_row.gd` (STAR_ICON preload); `ui/glyph_button.gd` caches textures in a static dictionary filled before drawing.
