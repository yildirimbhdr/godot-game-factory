---
id: 0006
title: Playtest screenshots showed the wrong moment after static periods
area: testing
severity: major
status: encoded
---

**What happened:** the "game over" screenshot of one theme showed the running game. The test passed, so only a human looking at the image could notice.
**Root cause:** marks used `Engine.get_frames_drawn()`, which only counts frames that were re-rendered. While the screen is static (pause menu) Godot skips drawing, but Movie Maker still records one frame per loop iteration, so frame numbers and file numbers drifted apart.
**Rule:** map marks to recorded frames with `Engine.get_process_frames()`. Marks are verified by checking the image, not only the log.
**Encoded in:** `templates/godot-base/autoload/playtest_driver.gd`.
