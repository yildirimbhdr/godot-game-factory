---
id: 0050
title: The first fallback font for Turkish drew the dotless i like the digit 1
area: ui
severity: minor
status: encoded
---

**What happened:** With VT323 as fallback, "Mağaraları" read "Mağaralar1" on the world banner.
**Root cause:** Glyph coverage was checked, legibility of the single letters was not.
**Rule:** After a glyph-coverage check also render the real words ("Mağaraları", "Yıldız", "İyi") in a contact sheet of candidate fonts and pick one whose ı, İ, ş, ğ read clearly (Jersey 10 passed, VT323 did not).
**Encoded in:** `skills/store-release/SKILL.md` (Fonts and glyphs); Slide Buddies `assets/ui/fonts/Jersey10-Regular.ttf`
