---
id: 0012
title: Kenney defaults read as generic (font, green buttons, flat background)
area: ui
severity: major
status: encoded
---

**What happened:** the first Unwind theme used the casual-green recipe and a Kenney font. The user rejected the font ("does not match the theme"), the green, and the empty flat background.
**Rule:** a game theme is finished only when it has (1) a font chosen for the game's mood (OFL fonts allowed, recorded in `ASSETS.md`), (2) a button/panel palette from the game's art (recipes support `tint`, `label_outline` and a local `font`), (3) a backdrop with gradient and faint game icons instead of a flat colour, (4) the same treatment on menu, level map, settings, pause and result screens. Show the menu, settings and in-game screenshots to the user in the first pass.
**Encoded in:** `scripts/build_theme.py` (tint, local font, label_outline), `skills/art-direction`, `scripts/dod_check.py` identity check
