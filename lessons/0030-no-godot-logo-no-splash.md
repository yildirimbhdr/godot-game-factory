---
id: 0030
title: A shipped game had no splash screen and showed the Godot logo at launch
area: workflow
severity: major
status: encoded
---

**What happened:** A game made with the plugin opened with the engine's boot logo and no screen of its own before the menu.

**Root cause:** the template's main scene was the menu and the engine boot splash was left at its default; no check looked at either.

**Rule:** every game starts on its own splash (logo and name, tap to skip) and never shows the Godot logo.

**Encoded in:** `templates/godot-base/ui/splash.*` and `project.godot` (boot splash off, splash as main scene), `playtest/smoke.json`
(marks `00_splash`), `scripts/dod_check.py` (`splash:` checks), `skills/godot-scaffold/SKILL.md`.
