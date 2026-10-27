---
id: 0047
title: Store screenshots used a flat purple gradient that looked nothing like the game
area: assets
severity: major
status: encoded
---

**What happened:** The first Slide Buddies screenshot set had a plain purple gradient behind the captions; the user said the real in-game cave backdrop would look better, and asked that every future game does the same.
**Root cause:** The generic store tool only knew gradients (made for the pastel Unwind) and no step looked at the game's own backdrop.
**Rule:** Store backgrounds (screenshots and feature graphic) come from the game's own backdrop art, one per world/theme, pixel-crisp and darkened towards the caption area; a flat gradient is only the fallback. Render the backdrop with a throwaway scene (`tools/backdrop_shot.tscn`: instance the game's backdrop with a world palette, `--write-movie`) into `store/bg/`, then set `shots[].bg` and `style.feature_bg` in `store.json`. Use the world that matches each frame.
**Encoded in:** `scripts/store_assets.py` (`backdrop()`, `shots[].bg`, `style.bg_image`, `style.feature_bg`), `skills/store-release/SKILL.md` (Look of the store graphics)
