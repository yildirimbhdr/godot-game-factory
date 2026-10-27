---
id: 0005
title: Theme build silently used the wrong texture because two source files had the same name
area: assets
severity: major
status: encoded
---

**What happened:** the sci-fi theme showed grey buttons instead of blue. `Blue/.../bar_round_gloss_large.png` and `Grey/.../bar_round_gloss_large.png` were copied to the same destination name and the second overwrote the first.
**Root cause:** destination names were built from the file name only; color/variant folders carry meaning in asset packs.
**Rule:** destination names must include the parent folders of the source file, and every generated theme is checked visually in a rendered screenshot, never only by "it loads".
**Encoded in:** `scripts/build_theme.py` (unique destination names).
