---
id: 0004
title: Playtest failed randomly because desktop window focus triggered auto-pause
area: testing
severity: major
status: encoded
---

**What happened:** about 1 in 8 smoke runs failed at the pause/resume steps. Logged evidence: an `APPLICATION_FOCUS_OUT` notification during play paused the game before the scripted tap.
**Root cause:** auto-pause on focus loss is correct on phones but desktop focus is unpredictable in automated runs.
**Rule:** tests must not depend on OS focus. Playtest mode ignores focus loss; backgrounding is tested explicitly with the `app_background` step. A flaky test is a bug in the harness: find the logged cause, do not retry until green.
**Encoded in:** `templates/godot-base/autoload/pause_manager.gd` and `playtest_driver.gd`; `playtest/smoke.json` now covers backgrounding.
