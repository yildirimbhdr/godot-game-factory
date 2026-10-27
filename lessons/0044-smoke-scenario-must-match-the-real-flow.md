---
id: 0044
title: The dod gate needs `smoke*` runs, but the template smoke scenario still expected the placeholder game (game over, "II" button)
area: testing
severity: minor
status: encoded
---

**What happened:** After the game became level based, `playtest/smoke.json` failed on "no button II", "Resume" and "Game Over" and the DoD gate could not pass.
**Root cause:** The smoke scenario was copied from the template once and never adapted when the placeholder game was replaced.
**Rule:** When the placeholder game is replaced, rewrite `playtest/smoke.json` at once: menu, settings sliders, Play, level_node, `pause_button` group, Resume, app_background, `autosolve`, clear, map. Keep it passing at all three screen shapes.
**Encoded in:** `skills/playtest-verify/SKILL.md`
