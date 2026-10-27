---
id: 0008
title: A sleeping display silently truncates playtest recordings
area: testing
severity: major
status: encoded
---

**What happened:** during a long session the Mac display slept. Movie Maker kept running game logic (all steps and logs looked fine) but stopped drawing: the recording had 32-125 frames instead of 320, and "marks" showed stale or dim frames. It looked like a game bug (frozen fade, nothing moving) and cost a long debugging detour.
**Rule:** `playtest.sh` runs Godot under `caffeinate -d -i` and wakes the display first. When screenshots look frozen, compare the `frames at 20 FPS` count in `log.txt` with `seconds*20` before suspecting the game.
**Also:** marks are now saved by the driver straight from the viewport (`--shots`), because movie frame numbers do not line up with process frames when drawing is skipped.
**Encoded in:** `scripts/playtest.sh` (runs under caffeinate; marks saved from the viewport via `--shots`)
