---
id: 0053
title: Store uploads went through the browser and cost far too many tokens
area: workflow
severity: major
status: encoded
---

**What happened:** The Slide Buddies release (App Store + Play) was done by driving both consoles in Chrome: hundreds of screenshot/click rounds. The user said the store work is fixed routine and Claude's tokens should go to making games.
**Root cause:** the plugin had no non-browser path: texts, images and builds existed as files but the only upload method was the console UI.
**Rule:** store uploads are scripted with fastlane (App Store Connect API key + Play service account, set up once). Claude prepares the release package and `store/declarations.md` (the answers for the forms no API can fill) and stops; the user runs `fl.sh` lanes and clicks the few legal declarations once per new app.
**Encoded in:** `scripts/fastlane_prepare.py`, `scripts/store_declarations.py`, `scripts/fastlane_setup.sh`, `scripts/fl.sh`, `skills/store-release/playbooks/fastlane.md`, `skills/store-release/SKILL.md` (Default: prepare and hand over)
