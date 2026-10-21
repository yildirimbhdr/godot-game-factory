---
id: 0025
title: Console automation wasted time on ignored inputs and impatient re-uploads
area: workflow
severity: minor
status: encoded
---

**What happened:** `form_input` silently did nothing on the App Store Connect and Play Console forms (fields stayed empty, selects stayed on "Choose"); and uploaded screenshot thumbnails look stuck as a grey cloud for 30-60+ s, so tiles were deleted and re-uploaded several times for nothing. A Google account chooser also hid the right Play account behind `/u/2/`.
**Root cause:** the first form attempt was not checked with a screenshot, and no waiting rule existed.
**Rule:** type with real clicks, select with click + typed text + Return, verify every field with a screenshot, wait a full minute before touching an upload, find the right Google account by its `/u/<n>/` index.
**Encoded in:** `skills/store-release/playbooks/browser-basics.md`
