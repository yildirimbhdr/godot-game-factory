---
id: 0017
title: Game audio was silent on a real iPhone (silent switch)
area: audio
severity: blocker
status: encoded
---

**What happened:** sounds and music passed every desktop playtest (strict audio check) but nothing played on the iPhone SE. Godot's iOS default audio session category is Ambient, which obeys the hardware silent switch and is muted by it; most players keep that switch on.
**Rule:** the template sets `audio/general/ios/session_category=3` (Playback; enum order in 4.7: Ambient 0, Multi Route 1, Play and Record 2, Playback 3, Record 4, Solo Ambient 5) so game audio plays regardless of the switch. After adding audio, ask the user to confirm sound on the real device (silent switch off AND on), because desktop tests cannot show this.
**Encoded in:** `templates/godot-base/project.godot` (`audio/general/ios/session_category=3`), device-sound item in `templates/godot-base/DOD.md`
