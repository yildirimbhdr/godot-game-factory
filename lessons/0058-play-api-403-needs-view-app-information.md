---
id: 0058
title: Play API uploads return 403 until the service account also has "View app information"
area: workflow
severity: major
status: encoded
---

**What happened:** `fastlane supply` failed 15 times with `403 The caller does not have permission` although the service account had release-to-production, testing tracks and manage store presence at account level, auth worked and the Android Publisher API was enabled. Waiting for propagation did not help.
**Root cause:** the account permission "View app information and download bulk reports (read-only)" was not ticked; the upload flow reads app information first.
**Rule:** give the Play service account all four account-level permissions (see playbooks/fastlane.md). On a 403, look at the account's permission page once; never loop retries (ban risk). After saving, one try works within minutes.
**Encoded in:** skills/store-release/playbooks/fastlane.md (Google Play tested route), scripts/play_publish/
