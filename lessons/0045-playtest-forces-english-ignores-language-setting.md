---
id: 0045
title: A playtest could not show the Turkish UI because the localization forced English and the `setting` step does not emit a change signal
area: testing
severity: minor
status: encoded
---

**What happened:** Seeding `language: tr` with the driver `setting` step changed nothing, so Turkish glyph problems could not be screenshotted.
**Root cause:** Localization forces English whenever `--playtest=` is on the command line, and `Settings.set_value(..., false)` does not notify.
**Rule:** Use `GF_LANG=tr scripts/playtest.sh ...` (environment variable read by the Localization autoload) to record a scenario in another language; a scenario that cannot match on English texts still produces marks to look at.
**Encoded in:** `templates/godot-base/autoload/localization.gd` in new games; Slide Buddies `autoload/localization.gd`
