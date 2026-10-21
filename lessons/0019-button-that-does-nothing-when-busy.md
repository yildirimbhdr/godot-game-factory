---
id: 0019
title: The hint button silently ignored taps while a screw was still flying
area: ui
severity: major
status: encoded
---

**What happened:** the hint button returned early whenever an animation was in flight (`_busy > 0`), with no feedback. On the phone the player tapped it right after a move, nothing happened, and it looked broken. The desktop test never pressed it mid-animation.
**Rule:** a control must never fail silently. While the game is busy, queue the request and run it when things settle (or show why it cannot run); out of uses shows a message; every failure path has visible feedback. Playtests press such buttons immediately after an action and when exhausted (`playtest/hint.json`).
**Encoded in:** `templates/modules/puzzle-unscrew/game.gd` (`_hint_pending`, popups), `playtest/hint.json`, `DOD.md` icon item
