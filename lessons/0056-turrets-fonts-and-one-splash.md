---
id: 0056
title: Mixed pixel fonts looked broken in Turkish, text was too small, two logo screens, enemies needed variety
area: ui
severity: major
status: encoded
---

**What happened:** On the phone Turkish letters (ğ ş ı İ) came from a different font than the rest and looked uneven; text was small; the iOS launch screen and an in-game splash both showed a logo (the second with the name); the game only had walking monsters.
**Root cause:** a fallback font patches missing glyphs but never matches size and weight; the splash rule asked for a game splash although the launch screen already shows the logo; one enemy type is enough for 12 levels, not 26.
**Rule:** pick ONE pixel font that has the target languages' glyphs (Pixelify Sans, OFL: checked for ğ ş ı İ) instead of a fallback mix, and keep body text at 54 px or more on a 1080 wide viewport; show exactly one logo screen (the platform launch image) and go straight to the menu; add a new enemy behaviour every few levels. Turret monster: stands at `cells[0]`, shoots a fireball along `cells` every `BOLT_GAP`, glows `BOLT_CHARGE` seconds before firing, and uses the same time-aware solver as patrols (kind "turret" in `SlideLogic.patrol_point`).
**Encoded in:** scripts/dod_check.py (splash rule accepts the launch image; rewarded-only games need no interstitial ids), skills/store-release (launch screen), templates/modules/ads-admob (rewarded only is fine); Slide Buddies `game/slide_logic.gd` is the reference for turrets
