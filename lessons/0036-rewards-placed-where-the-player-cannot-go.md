---
id: 0036
title: Fish and stars sat in tunnel cells the penguin could never reach (or only reach by dying)
area: workflow
severity: major
status: encoded
---

**What happened:** The first level factory put fish on every floor cell it carved. The user's screenshots showed fish in a pocket nobody can slide into, and stars/fish next to a spike that can only be reached by dying.
**Root cause:** the factory proved the level solvable, but never asked which cells the player can actually pass. "A path exists" is not "the player can use every cell".
**Rule:** place collectibles only on cells the solver says a safe move can pass (`SlideLogic.analyze()`: safe vs death cells); wall off floor nobody can reach; keep dead-end hazard tunnels but never put rewards in them. Any level generator for a movement puzzle ends with this reachability pass.
**Encoded in:** `templates/modules`-style reference in `slide-buddies/tools/gen_levels.gd` and `game/slide_logic.gd` (analyze), `skills/physics-puzzle-design` sibling note in `skills/ideation`-level design rules: see the "reachability pass" item in the slide-puzzle notes.
