---
id: 0016
title: The obvious shortcut beat every level
area: workflow
severity: blocker
status: encoded
---

**What happened:** my difficulty metric used a random bot and a heuristic bot that was itself the greedy strategy; levels scored "hard" while a human could win by only tapping screws matching the 2-3 visible jars. The user found it in one play-through.
**Rule:** write down the simplest strategy a player will discover (here: match the visible containers) and simulate exactly that; the level checker fails any level above its allowed greedy win rate. Add structure that breaks the shortcut (deepest colours first, hidden screws, small buffer) and prove solvability by search.
**Encoded in:** `Figure.simulate(GREEDY)` + `Figure.solve` in `templates/modules/puzzle-unscrew/figure.gd`, enforced by `check_levels.gd`
