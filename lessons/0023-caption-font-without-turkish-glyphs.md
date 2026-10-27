---
id: 0023
title: Turkish store captions shipped with missing letters because the font lacked them
area: assets
severity: major
status: encoded
---

**What happened:** the Turkish screenshot caption "Eşleştir" was rendered as "E le tir": the game font (Lilita One) has no `ş ğ İ`. The first replacement font (Fredoka, the copy from Google Fonts) drew empty boxes for the same letters, and a first coverage check did not notice because the box is not blank. The user spotted it on the contact sheet.
**Root cause:** the pipeline never verified that the font can draw the text of each locale, and a "not blank" test cannot detect tofu boxes.
**Rule:** compare each character's rendering with the font's rendering of U+FFFF (a character no font has); refuse to build when any caption character matches it. Pick a per-locale font and look at every locale's sheet.
**Encoded in:** `scripts/store_assets.py` (`missing_glyphs`, `style.fonts.<locale>`), `skills/store-release/SKILL.md`
