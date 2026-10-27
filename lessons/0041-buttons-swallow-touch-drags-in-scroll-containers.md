---
id: 0041
title: The level map did not scroll on the phone because buttons and a STOP content control swallowed the touch drag
area: ui
severity: major
status: encoded
---

**What happened:** The map scrolled in desktop captures but a finger drag did nothing on the iPhone.
**Root cause:** the ScrollContainer relies on touch events reaching it; its content and the level buttons (mouse_filter STOP) consumed them. Playtests never drag, so nothing caught it.
**Rule:** for a scrolling map with buttons, handle drag scrolling yourself in `_input` (with a small dead zone, inertia, and a "was dragging" flag that cancels the button tap); set the containers to IGNORE. Always try scrolling on a real device before calling a map done.
**Encoded in:** `slide-buddies/ui/level_select.gd` (`_input`, `_moved`).
