---
id: 0057
title: Adding ads and analytics needs the store privacy forms redone in both consoles
area: workflow
severity: major
status: encoded
---

**What happened:** After AdMob and Firebase Analytics went in (1.1.0), both stores still said "no data collected / no ads".
**Root cause:** the privacy forms are separate from the build; nothing reminded us to redo them.
**Rule:** whenever `addons/admob` or `addons/godotx_firebase` appears, re-run `store_declarations.py` and update before the new version is submitted. Apple App Privacy: Device ID (Analytics + Third-Party Advertising), Product Interaction (Analytics), Advertising Data (Third-Party Advertising), Performance Data and Other Diagnostic Data (Analytics), all "not linked to identity", tracking "No" while no ATT prompt exists; age rating: Advertising = Yes. Play: Ads = Yes; Data safety: collected Device IDs (shared), App interactions, Diagnostics (encrypted, no account); Advertising ID = Yes (advertising, analytics, fraud prevention).
**Encoded in:** scripts/store_declarations.py (answer sheet), skills/store-release (when the owner asks, Claude can fill the forms in the browser; the Play data-safety page breaks horizontally if sections are expanded by coordinates, use find/refs)
