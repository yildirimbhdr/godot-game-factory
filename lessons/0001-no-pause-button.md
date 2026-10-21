---
id: 0001
title: Game shipped without a pause button
area: ui
severity: major
status: encoded
---

**What happened:** an earlier game was declared finished but had no way to pause it.
**Root cause:** no Definition of Done; basic UI requirements were never listed, so they were forgotten.
**Rule:** every game has an on-screen pause button reachable during play, a pause menu, and auto-pause when the app goes to the background.
**Encoded in:** `templates/godot-base` (Hud pause button, PauseManager, back-button and auto-pause handling) and `playtest/smoke.json` (expects the pause flow). The Definition of Done gate in `playtest-verify` will check it for every game.
