---
id: 0002
title: Screenshots from a different resolution were cropped, hiding the real layout
area: testing
severity: major
status: encoded
---

**What happened:** `godot --resolution 450x975 --write-movie` produced frames at the project's 540x960 size, so a tall-screen test showed a cropped, misleading image that looked like a layout bug.
**Root cause:** Movie Maker takes its frame size from the project window override, not from `--resolution`.
**Rule:** Change test resolution with a temporary `override.cfg`; always check the captured image size matches what was requested.
**Encoded in:** `scripts/playtest.sh` (`--resolution` writes and cleans up `override.cfg`).
