---
id: 0046
title: Second end-to-end iOS release: what the Apple consoles looked like in October 2026
area: workflow
severity: minor
status: encoded
---

**What happened:** Registering the App ID, creating the app record, building and uploading took about 20 minutes with Claude in Chrome. The Apple Developer list showed the new id immediately; the App Store Connect list needed a page reload before the new app appeared.
**Root cause:** n/a (record of a working path)
**Rule:** Follow `playbooks/app-store-connect.md`; extra facts: the version page now has tabs "Header and Search Results" and "App Previews and Screenshots"; one `file_upload` call accepts all 6 screenshots (about 3 MB); `type` into the 1,300 character description reports a CDP timeout but the text arrives, so check the counter before retyping; the Paid Applications banner does not block creating the app, only submitting.
**Encoded in:** `skills/store-release/playbooks/app-store-connect.md`
