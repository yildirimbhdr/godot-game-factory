---
id: 0003
title: HUD pause button sat almost on the screen edge
area: ui
severity: minor
status: encoded
---

**What happened:** on a real iPhone SE the pause button looked glued to the side edge; only the top had some room.
**Root cause:** the 24 px default margin (about 8 pt on a phone) was only judged on a desktop screenshot.
**Rule:** keep at least 48 px (about 16 pt) between HUD elements and every screen edge, and judge margins on a real device.
**Encoded in:** `templates/godot-base/ui/safe_area.gd` (`min_margin = 48`).
