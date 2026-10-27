---
id: 0029
title: On a second machine the agent said "tested" while nothing was ever played on screen
area: testing
severity: major
status: encoded
---

**What happened:** Here the user sees Godot open and the game played during tests. On another PC the agent reported
"tested" with nothing visible and no way for the user to check; the game was not actually played.

**Root cause:** the word "tested" had no required evidence, and headless scripts or simulations were not excluded from it.

**Rule:** a test is a visible Godot run (`playtest.sh` or `play.sh`); every claim lists the scenario, log and marks that were
opened and what they show.

**Encoded in:** `skills/playtest-verify/SKILL.md` ("Testing must be visible and evidenced"), `scripts/play.sh`,
`skills/godot-scaffold/SKILL.md` (order, step 5), the Stop hook stamps (`scripts/dod_check.py`) which only `playtest.sh` writes.
