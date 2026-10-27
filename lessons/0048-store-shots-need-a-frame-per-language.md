---
id: 0048
title: Turkish screenshots showed English UI text (world name, "Level Clear!") because one set of raw frames served both languages
area: assets
severity: minor
status: encoded
---

**What happened:** The Turkish App Store set reused the English frames, so the map banner and the clear dialog stayed English while the captions were Turkish.
**Root cause:** `store_assets.py` took one `frame` per shot; the capture scenarios tapped English texts, so a Turkish recording failed.
**Rule:** Shots whose frame contains UI text get a `frame_<locale>` captured with `GF_LANG=<locale>`; tap by coordinates (or a group) instead of by English text so the same scenario runs in every language. Translate every visible string first (world names, shop, tutorial, result dialog).
**Encoded in:** `scripts/store_assets.py` (`frame_<locale>`), `skills/store-release/SKILL.md`
