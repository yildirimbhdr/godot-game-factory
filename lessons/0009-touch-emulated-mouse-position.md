---
id: 0009
title: get_global_mouse_position() is wrong for touch-emulated clicks
area: testing
severity: major
status: encoded
---

**What happened:** with `emulate_mouse_from_touch`, only the first scripted tap hit a screw; later taps used a stale cursor position and did nothing.
**Rule:** read the position from the event (`event.position`) inside `_unhandled_input`, never from `get_global_mouse_position()` for taps. Playtests tap through `InputEventScreenTouch`, so this also matches real touch devices.
**Encoded in:** `templates/modules/puzzle-unscrew/game.gd` (event.position through the canvas transform), `skills/physics-puzzle-design` section 3
