---
id: 0035
title: Quoted review times (7 days, 12 testers x 14 days) did not apply to an established developer account
area: workflow
severity: minor
status: encoded
---

**What happened:** The plan assumed the documented Play gates for new personal accounts. The user's account already had production apps: no closed test was asked for and production went live about two hours after submission.
**Root cause:** the general rule was applied to this account without reading the dashboard's own wording.
**Rule:** read the console dashboard (and the account's existing apps) before quoting a date or requiring a closed test; state the documented worst case and the observed case separately.
**Encoded in:** `skills/store-release/playbooks/google-play.md` step 3.
