---
id: 0055
title: Features appeared all at once, Godot launch logo showed on iOS, language caption overflowed
area: ui
severity: major
status: encoded
---

**What happened:** On the phone the first levels already showed boxes and hammer, monsters appeared early, hint texts stayed English in Turkish, the settings language button text ran out of its box, the Godot logo showed on the iOS launch screen, and the penguin sat so low that the thumb hit the buttons.
**Root cause:** (1) no rule that new mechanics come in one at a time; (2) hint strings built with ternaries are invisible to a grep for `tr(`; (3) `boot_splash/show_image=false` does not cover the iOS launch storyboard, which shows Godot's logo unless `storyboard/custom_image@2x/@3x` are set; (4) button captions were translated words; (5) the camera lead was tuned for looking ahead, not for the hand.
**Rule:** introduce one mechanic per milestone (box tools from level 6, patrol monsters from level 8) with a one-time short info card (`HowTo.show_once`); keep the first-run tutorial free of later mechanics; scan every string literal in game/ui for a `tr` entry, not only `tr(` calls; set the iOS launch image in the preset; captions inside buttons use short codes; keep the player character at or above the screen middle (CAMERA_LEAD about 130 at 1920 high).
**Encoded in:** skills/game-ideation/SKILL.md (Pacing of new mechanics), skills/store-release/SKILL.md (iOS launch screen), templates/godot-base (CAMERA_LEAD note)
