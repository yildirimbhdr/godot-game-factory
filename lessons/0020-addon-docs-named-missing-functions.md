---
id: 0020
title: The ad addon's bundled docs named functions that do not exist
area: workflow
severity: minor
status: encoded
---

**What happened:** the first `Ads` autoload was written from the AdMob addon's own `skills/*.md` (it calls `ConsentForm.load_and_show_consent_form_if_required`). That function does not exist in the addon source; the code would have failed only on a device, because every AdMob class is a silent no-op in the editor. Caught before the user saw it by grepping the source.
**Root cause:** third-party docs (and AI-written docs shipped with addons) were trusted over the code; the editor cannot exercise native-only plugins.
**Rule:** before using any function of a third-party addon, grep it in the addon's source or copy it from its sample scenes; for native plugins the first real check is a device console, not the editor.
**Encoded in:** `skills/monetization/SKILL.md` (hard rules), `templates/modules/ads-admob/README.md` (notes), device-console check in the monetization test order
