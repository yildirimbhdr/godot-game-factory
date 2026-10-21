---
id: 0026
title: The first build killed the player in 1.5 seconds, so nobody ever saw the mechanic
area: workflow
severity: major
status: encoded
---

**What happened:** Pastel Serpent shipped its first playable with lethal walls on a 15-wide board.
A measurement script showed the average no-input run ended in **9 ticks — 1.5 seconds**. Three
separate playtests "failed" on `expect_paused` after `app_background`; the real cause was that the
snake had already died, so `gameplay_active` was false and backgrounding legitimately did not pause.
The screenshots showed a Game Over panel the log never mentioned.

**Root cause:** time-to-first-death was never measured, and a failing assertion was read as a bug in
the feature being asserted instead of a symptom of game state.

**Rule:** measure time-to-first-death with a no-input run AND a greedy-bot run before tuning
anything; a casual game that ends before the core mechanic is visible has no clip and no player.
Target a run long enough to show the mechanic at least twice. When a playtest assertion about UI
state fails, read the mark screenshot before changing the UI code — the game may simply be in a
different state than the scenario assumed.

**Encoded in:** `templates/godot-base/DOD.md` (pacing row), `skills/godot-scaffold/SKILL.md` section 4
("Measure pacing before tuning it"), `skills/playtest-verify/SKILL.md` (DoD pacing row and the "when something
fails" rule about reading the mark screenshot first).
