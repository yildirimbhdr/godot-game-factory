---
id: 0059
title: A never-published Play app needs the "draft apps" permission for its store listing
area: workflow
severity: major
status: encoded
---

**What happened:** for a brand-new app the first AAB upload worked, but every store-listing upload (texts, images) failed at commit with `Invalid request - The caller does not have permission`, although the service account already had the four account permissions of lesson 0058.
**Root cause:** until its first release the app counts as a draft, and changing a draft's listing needs the separate account permission "Create, edit, and delete draft apps". Published apps do not need it, so older games never showed the problem.
**Rule:** tick that fifth permission once at account level (the user does it; permissions are never changed by Claude). After that every future new app works. Do not retry in a loop.
**Encoded in:** skills/store-release/playbooks/fastlane.md, scripts/play_publish/ship.sh (the manual step list), docs/decisions/0022.
