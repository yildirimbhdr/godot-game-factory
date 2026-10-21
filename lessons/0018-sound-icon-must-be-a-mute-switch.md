---
id: 0018
title: A speaker icon that only decorates a slider is a bug
area: ui
severity: major
status: encoded
---

**What happened:** the settings screen showed a speaker icon next to the volume slider. The user tapped the icon expecting mute and nothing happened; there was also no muted glyph.
**Rule:** in any settings UI an audio icon is a toggle. Tapping it mutes that channel at once (remember the previous volume, restore it on the next tap), swaps to a muted glyph (speaker with X, crossed-out note), and the glyph also flips when the slider is dragged to zero or back. Vibration and similar toggles show an off state too. `IconButton` has `glyph_off` for this; every icon you place must do what players expect from that icon in other games.
**Encoded in:** `IconButton.glyph_off`, `templates/modules/common/settings_panel.gd`, `skills/godot-scaffold`, `playtest/mute.json`, `DOD.md`
