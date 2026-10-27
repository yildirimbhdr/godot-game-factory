---
id: 0051
title: Add for Review failed for a missing privacy URL that existed only for the primary language; age ratings took seven clicking steps
area: workflow
severity: minor
status: encoded
---

**What happened:** "Unable to Add for Review: enter a Privacy Policy URL in App Privacy" appeared after the URL had been entered for English only; the Turkish locale needs its own. The age-rating questionnaire has 7 steps with many radios.
**Root cause:** App Privacy stores the policy URL per locale; the questionnaire is long.
**Rule:** Enter the privacy URL for every localized language in App Privacy (language menu, Edit). The age-rating radios have stable names and values, so a short page script can set them (`input[name=...][value=NONE|false|INFREQUENT]` then click Next); keep the answers honest: cartoon creatures and spikes that restart the level were answered "cartoon or fantasy violence: infrequent" and gave 9+. Content Rights: freely licensed third-party assets (Kenney, OFL fonts, generated art) are third-party content you hold rights to, so answer "Yes, I have the necessary rights". Release order that worked: version page saved (needs review phone) -> App Privacy (Data Not Collected, publish, URL per locale) -> Pricing (free, all countries) -> App Information (category, content rights, age rating) -> Add for Review -> Submit for Review.
**Encoded in:** `skills/store-release/playbooks/app-store-connect.md` step 11
