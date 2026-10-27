---
id: 0049
title: App Store Connect: locale text vanished, a language click hit the wrong item, and one required field blocked the whole page
area: workflow
severity: major
status: encoded
---

**What happened:** (1) Turkish promo/description/keywords typed and "saved" were empty after a later reload. (2) Clicking a language through a `ref` landed on a neighbouring language because the open menu list scrolled (Ukrainian and Bangla were added by accident). (3) The review contact phone number is required and a missing value blocks Save for the entire version page.
**Root cause:** Typed text was trusted without a reload check; refs were clicked in a scrolling popup; the phone number was not asked for up front.
**Rule:** After saving any locale, reload and re-open it to confirm the text is still there before moving on. In language menus scroll with the mouse wheel and click by screenshot coordinates, never by ref; discard accidental locales with a forced reload before saving. Ask the user for the review contact phone number at the start of the release, together with the email.
**Encoded in:** `skills/store-release/playbooks/app-store-connect.md`, `skills/store-release/playbooks/browser-basics.md`
