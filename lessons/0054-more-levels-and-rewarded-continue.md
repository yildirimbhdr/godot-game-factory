---
id: 0054
title: Growing a shipped game (levels, buddies, rewarded continue) broke stale playtests and needed a no-reshuffle generator
area: workflow
severity: minor
status: encoded
---

**What happened:** Slide Buddies went from 14 to 26 levels, 3 to 5 buddies and got a rewarded "continue after death". Three playtests failed only because they hard-coded the old level count (`expect_group_count 14`) or an old flow (autosolve before a level was open). PixelLab downloads through a zsh loop also failed silently (`set -- $p` does not word-split in zsh).
**Root cause:** playtests encode content counts; the generator uses the level index in its seeds, so a changed formula could reshuffle shipped levels.
**Rule:** (1) extend a seeded level generator only for indexes beyond the shipped ones and diff the old levels against a saved copy; (2) derive counts in playtests from `Levels.DATA.size()` or re-run all playtests after adding content; (3) a rewarded continue is offered once per try, restores the state before the fatal move (`Board.revive`), never blocks when no ad is ready, and logs `continue_offered` / `continue_used`; (4) in zsh use explicit functions with arguments, not `set -- $var`; PixelLab character zips come from `https://api.pixellab.ai/mcp/characters/<id>/download` (Idle/rotations/*.png).
**Encoded in:** skills/game-ideation/SKILL.md (Pacing of new mechanics); AdMob wiring done in Slide Buddies (autoload/ads.gd from templates/modules/ads-admob)
