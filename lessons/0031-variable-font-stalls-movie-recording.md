---
id: 0031
title: A variable font made the playtest recording stop after 3 seconds while the test kept passing
area: testing
severity: major
status: encoded
---

**What happened:** After switching the theme to a variable TTF (Nunito[wght]) every screenshot after the first 61 frames showed
the same stale menu, yet all text expectations passed. The movie had 61 frames instead of 260.

**Root cause:** the engine stopped presenting frames in Movie Maker mode with that font; the game logic kept running, so
`expect_text` passed while marks were stale. Marks identical to the previous one (same file size) are the tell.

**Rule:** use static fonts only, and check `frames at 20 FPS` in `log.txt` against `--seconds * 20` before trusting marks.

**Encoded in:** `scripts/build_theme.py` (refuses variable fonts), `skills/playtest-verify/SKILL.md` (frame-count check).
