---
id: 0028
title: On a second machine the agent skipped the template, simulated the game in Python and had no level screen or fresh idea
area: process
severity: major
status: encoded
---

**What happened:** On another PC with the plugin installed, "make a game" produced about 30 minutes of Python
(an algorithm simulation), no copy of `godot-base`, no Godot run, no level select screen, and "find an idea" only
returned Unwind-style puzzles. Godot was installed and worked as soon as the user asked for it.

**Root cause:** the workflow was advice, not a sequence. Skills load only when their description matches, nothing said
"template first, Godot first", nothing forbade a Python simulation, level select lived only inside one module, and the
only ideation material in the plugin was the pilot game's puzzle skill.

**Rule:** start in order (doctor, brief, copy template, Godot scenes, screenshot); never build or "test" the game logic
outside Godot; level-based games must have a level select screen; ideas come from many genres, not the pilot.

**Encoded in:** `skills/godot-scaffold/SKILL.md` (section 0 and "Structure decision"), `skills/game-ideation/SKILL.md`,
`templates/godot-base/DOD.md` and `skills/playtest-verify/SKILL.md` (level screen / high score item),
`hooks/hooks.json` + `scripts/session_hook.sh` (session-start reminder of this order).
