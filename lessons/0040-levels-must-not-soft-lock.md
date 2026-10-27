---
id: 0040
title: Some levels let the player enter a region (for a star) and never get back out
area: workflow
severity: major
status: encoded
---

**What happened:** The user, playing on the phone, found levels where going for a star put the penguin in a place with no way back to the exit; the only fix was quitting the level.
**Root cause:** the factory proved "all stars can be collected in one run from the start" but never checked that EVERY reachable position can still reach the exit. In a sliding puzzle moves are not always reversible, so dead pockets exist.
**Rule:** a movement-puzzle generator must reject any level with a soft-lock cell (a reachable position from which the exit is unreachable), and the game always offers Restart and Undo as a safety valve.
**Encoded in:** `slide-buddies/game/slide_logic.gd` (`softlock_cells`), `tools/gen_levels.gd` (rejects), `tools/check_levels.gd` (reports), game HUD Restart/Undo.
