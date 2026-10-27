# 0016 - Store release is managed by the plugin

Date: 2026-10-21. Status: assets and texts built for the pilot; console work waits for the user's decisions.

**Decision**
- A `store-release` skill plus three generic scripts (`store_assets.py`, `store_listing_check.py`, `privacy_policy.py`) own the path from "game done" to
  "submitted". Content lives per game in `<game>/store/`.
- Locales: English and Turkish first (user choice). Both stores in parallel; the privacy policy page goes to Firebase Hosting (a new site, never over an existing app's site).
- Screenshots are composed (caption + rounded game frame on the game's own gradient) from real playtest frames. macOS clamps the Movie Maker window to the
  screen height (1664 px here), so frames are captured at 936x1664 and placed on a ~1085 px wide card (about 1.16x upscale for the 1320x2868 size).
  The playtest driver got a `setting` step to stage progress for the level-map shot.
- The user keeps: signing keys and passwords, payments/tax/identity, age-rating and data declarations, the final submit click, and decides which contact email is public.

**Specs used** (official pages): Play icon 512, feature graphic 1024x500, screenshots 320-3840 px with 2:1 max ratio, short description 80;
App Store iPhone 6.3" (1206x2622 / 1179x2556) required, 6.9" optional, keywords 100 bytes, subtitle 30, promo 170.
**Schedule risk:** new personal Play accounts need 12 testers for 14 continuous days before production access.

**Addendum (2026-10-21, user decisions):** captions and texts never state level counts (they change); public contact email is the user's address and the
developer line is "<brand> (<developer name>)" (brand plus name), kept in a per-user profile (`~/.game-factory/profile.json`) so it is asked once; the Android upload keystore
was created for the user (`~/.game-factory/keystores/`, password in the macOS Keychain, the user backs the file up); privacy and support pages live on a new
Firebase Hosting site of the user's shared Firebase project (never the project's default site). A dashboard page (`scripts/dashboard.py`) shows the profile and all games
locally; it is per user and never uploaded.

**Addendum 2 (2026-10-21):** the pilot went through both consoles with the user's signed-in Chrome: Play app record, explicit Apple App ID, App Store Connect record, iOS build upload, EN+TR App Store text and
screenshots. What was learned is in `skills/store-release/playbooks/` (browser rules, Play, App Store Connect) and `scripts/ios_release.sh`; lessons 0024 and 0025. Still the user's: agreements, declarations, privacy labels, age ratings, final submit.
