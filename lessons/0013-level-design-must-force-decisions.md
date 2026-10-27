---
id: 0013
title: A level set where every move is free is not a puzzle
area: workflow
severity: blocker
status: encoded
---

**What happened:** Unwind's 8 levels passed every geometry check but could be cleared by tapping any screw in any order (random play won ~100% of the time), screws were packed 74 px apart, and the pause/result screens were word buttons with no reward effects.
**Rule:** measure a level by simulating a naive and a smart player (see `skills/physics-puzzle-design` section 6) and tune until the naive win rate falls with the level number; hide fasteners under pieces; keep spacing >= ~100 px; add the reward loop and icon buttons in the first build, not after feedback.
**Encoded in:** `skills/physics-puzzle-design` section 6, `templates/modules/puzzle-unscrew/tools/check_levels.gd`
