---
id: 0038
title: Every Kenney font lacks the Turkish letters (g-breve, s-cedilla, dotless i, capital I-dot)
area: ui
severity: major
status: encoded
---

**What happened:** For a pixel UI, the cached Kenney fonts (Pixel, Pixel Square, Mini, High, Future ...) were checked with a glyph test. All of them miss ğ ş ı Ğ Ş İ, but the game ships a Turkish translation.
**Root cause:** pixel/retro fonts are usually ASCII-only; the glyph check was not part of picking a UI font (lesson 0023 only covered store captions).
**Rule:** before choosing a UI font, render ğüşıöçĞÜŞİÖÇ with it (the PIL "missing glyph" comparison in the slide-buddies notes) and pick one that has all of them. For pixel looks a font with Latin Extended-A is needed (needs a user-approved download; avoid variable fonts, lesson 0031).
**Encoded in:** `skills/store-release/SKILL.md` (Fonts and glyphs). Fix used in Slide Buddies: wrap the pixel font in a `FontVariation` whose `fallbacks` hold Jersey 10 (OFL, Google Fonts; VT323 was rejected, its dotless i looked like a 1, lesson 0050), so only ğ ş ı Ğ Ş İ come from the fallback; verified with a throwaway scene. Whole-font replacement is not needed.
