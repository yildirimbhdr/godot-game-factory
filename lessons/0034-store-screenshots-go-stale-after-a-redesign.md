---
id: 0034
title: App Store screenshots still showed the old level design after the 1.1.0 redesign
area: workflow
severity: major
status: encoded
---

**What happened:** Version 1.1.0 changed the whole level design, but the 6.3" App Store screenshots uploaded for 1.0.0 were reused and the build went into review with the old look.
**Root cause:** screenshots were treated as a one-time release asset; nothing linked a visual change to re-capturing them.
**Rule:** a `release.py bump minor|major` that changes what the player sees also requires re-running `store_assets.py` and re-uploading screenshots before the store is marked `in_review`.
**Encoded in:** `skills/store-release/SKILL.md` (Updating a game that is already published, step 3).
