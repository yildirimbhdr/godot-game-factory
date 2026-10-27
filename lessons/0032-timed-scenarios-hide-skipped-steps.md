---
id: 0032
title: A timed all-levels scenario "passed" while the game was still on level 37
area: testing
severity: major
status: encoded
---

**What happened:** A scenario that solved a level and tapped Next every 2 seconds passed all its expectations, but its last screenshot
showed level 37 of 60. Some Next taps landed during the scene fade and were ignored; `expect_text "Level Clear!"` still passed because the
previous win overlay was still on screen.

**Root cause:** time-driven steps cannot know what state the game is in, and an expectation on text that may be stale proves nothing.

**Rule:** to play through many levels, let the game drive itself (`start_autoplay(n)`: solve, win screen, Next through the real button), and
end with an expectation that only the final state satisfies (the last level number, "180 / 180" stars).

**Encoded in:** `templates/modules/light-puzzle/game.gd` (`start_autoplay`) and `playtest/all_levels.json`, `skills/playtest-verify/SKILL.md`.
