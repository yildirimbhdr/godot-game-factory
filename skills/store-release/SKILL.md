---
name: store-release
description: Take a finished game to the App Store and Google Play - store graphics (icon, feature graphic/banner, captioned screenshots), listing texts in several languages, privacy policy page, release builds, console forms and the release checklist. Use when the user says the game is ready to publish, asks for store assets, screenshots, a logo/banner, a listing, a privacy policy, or submission.
---

# Store release

Starts only when the game's Definition of Done passes with `dod_check.py <game> --release`. Everything lives in `<game>/store/`
(`store.json`, `listing.json`, `policy.json`, `raw/`, `out/`); the scripts are generic, the content is per game.

## Who does what
| Step | Claude | User |
|---|---|---|
| Icons, feature graphic (the Play "banner"), captioned screenshots | `scripts/store_assets.py` from `store.json` | approves the contact sheet |
| Listing texts per locale | writes `listing.json`, `scripts/store_listing_check.py` enforces the limits | approves wording, picks languages |
| Privacy policy page | `scripts/privacy_policy.py` (reads which SDKs the game ships), publishes to hosting | gives developer name and a **public** contact email (ask; never use the account email unasked), approves the text |
| Release builds | AAB / iOS archive | keeps the signing keys and passwords |
| Console records and forms | fills them with Claude in Chrome after asking (as done for AdMob) | payments, tax, identity, and the final "submit/publish" click, age rating, data-safety and privacy-label declarations are confirmed by the user |

Never click a final submit/publish/confirm, enter payment or tax data, or publish someone's email without a clear yes in chat.

## Steps
1. **Gate:** `python3 scripts/dod_check.py <game> --release`. Fix the AdMob consent message and store listing in AdMob (ads are limited until the store listing exists), add `app-ads.txt` on the developer website.
2. **Decide with the user, but read the profile first** (`scripts/gf_profile.py show`, see the `dashboard` skill): ask only what is empty and save it. Needed: locales, target audience (the privacy policy says "not directed to children under 13"; if the game is for kids the ad and policy setup changes), public contact email, developer name or brand, hosting site.
   Do not put numbers that change (level counts) into captions or listing texts; say "cozy levels across themed worlds".
3. **Raw frames** (macOS clamps the window to the screen height, so capture 936x1664, never taller):
   `scripts/playtest.sh <game> playtest/smoke.json --resolution 936x1664 --out <game>/store/raw/smoke` plus per-level runs
   (`UNWIND_LEVEL=n ... store_level.json`) and a map run that seeds progress with the driver's `setting` step. Use `mark` times after
   the map has loaded (about 5 s). Look at every frame before composing.
4. `python3 scripts/store_assets.py all <game>` -> `store/out/` (icons, `play_feature_1024x500.png`, `apple/<locale>/iphone_6.9|6.3/NN.png`,
   `play/<locale>/phone/NN.png`). Make a contact sheet, look at it, show the user, wait for approval. Captions are localized; the UI in the frames is icon-only on purpose.
5. `python3 scripts/store_listing_check.py <game>` must say `listing OK`.
6. `python3 scripts/privacy_policy.py <game>` writes `store/out/site/<slug>/privacy` and `support`. Read it, then `scripts/site_deploy.sh` publishes every game's pages to the user's own multi-site Hosting site (profile `hosting_site`; created once with `firebase hosting:sites:create`; the script refuses to touch a project's default site because that belongs to an app). Save the URLs in `store/status.json` and enter them in both consoles.
7. Release builds and uploads (see below), then the console forms, then wait for review. Console work follows the playbooks in `playbooks/`: read `browser-basics.md` first, then `google-play.md` and `app-store-connect.md`; update them when a console changes.

## Fonts and glyphs
`store_assets.py` refuses to render a caption with characters its font lacks (Lilita One has no `ş ğ İ`; the Turkish captions use Baloo 2 ExtraBold, OFL, kept in `<game>/store/fonts/` with its license). Set `style.fonts.<locale>` in `store.json` per language and look at every locale's contact sheet.

## Specs (official pages, checked 2026-10-21; recheck before relying)
- **Google Play:** icon 512x512 PNG with alpha <=1024 KB; feature graphic 1024x500 JPEG/24-bit PNG no alpha; phone screenshots 2-8, each side 320-3840 px, long side <= 2x short side; for games at least 3 shots at 1080x1920 or 1920x1080 recommended; short description 80 chars; promo video is a YouTube URL. **New personal developer accounts (created after 13 Nov 2023) need a closed test with at least 12 testers opted in for 14 continuous days before production access** (Dashboard > Apply for production, review usually <= 7 days). Plan the release date around it.
- **App Store:** 1-10 screenshots per size, PNG/JPEG, no alpha. iPhone needs at least one 6.3" shot (1206x2622 or 1179x2556); 6.9" (1320x2868) is optional and scales down. iPad 13" (2064x2752) only if the app runs on iPad (Unwind is iPhone only: `application/targeted_device_family=0`). Name <=30, subtitle <=30, promo text <=170, description <=4000, keywords <=100 bytes, support URL required (real contact info), copyright required, What's New only from version 2. Icon 1024x1024 without alpha.
- Texts for iOS keywords/ASO beyond the basics: the `vibe-aso` skill.

## Builds
- **Android:** `scripts/setup-android-gradle.sh` once, an "Android Release" preset (Gradle, `gradle_build/export_format=1`, `package/signed=true`), then `scripts/android_release.sh <game> <out.aab>`: it signs with the upload keystore from the profile and reads the password from the macOS Keychain, so no secret is ever in the repo or on the command line. One upload keystore can serve all of the user's games with Play App Signing; the user must back the `.keystore` file up (losing it needs a Play support reset). Version code increases every upload.
- **iOS:** `scripts/ios_release.sh <game> <work-dir> [--upload]` does export, archive and (with `--upload`) the App Store Connect upload through the Xcode-signed-in Apple account: no API key needed. It contains the fix for Godot's manual Distribution identity conflicting with automatic signing. The explicit App ID and the ASC app record must exist first. Build number (`application/version`) increases every upload; `application/short_version` is the marketing version.
- Re-run the device test with the release build before submitting (ads must still be TEST units until the AdMob store listing is approved, then LIVE).

## Release checklist
- [ ] `dod_check.py --release` passes; AdMob GDPR consent message created and assigned; AdMob store listing added; `app-ads.txt` live
- [ ] Icons, feature graphic, screenshots approved (all locales); listing texts approved and `listing OK`
- [ ] Privacy policy URL live and entered in both consoles; Play data-safety form and App Privacy labels match the SDKs (AdMob: ad ID, usage; Firebase Analytics: app interactions)
- [ ] Age rating questionnaires done by the user; Play target audience and ads declaration set
- [ ] Play closed test running with >= 12 testers for 14 days, then production application
- [ ] Release AAB and iOS build installed and played on a device; version numbers bumped
- [ ] User pressed the final submit/publish in each console

## Updating a game that is already published
Track every change so the dashboard always shows what is in development and what each store has (`scripts/release.py`).

1. While working, add a line per user-visible change: `release.py note <game> "New world: Ocean"` (goes under Unreleased in CHANGELOG.md).
2. Before building for a store, bump: `release.py bump <game> patch|minor|major`.
   patch = fixes and tuning, minor = new levels, worlds or features, major = redesign or new core loop. Pick one and tell the user why.
   The build number rises by one on every bump (Android version/code, iOS build) and never goes back; both stores reject a reused build number.
3. Update `whats_new` for every locale in store/listing.json (the bump prints this reminder), rebuild with android_release.sh / ios_release.sh.
4. After each real step in a console, record it: `release.py store <game> play|apple uploaded|internal_test|in_review|live|rejected|removed [--track production]`.
   Record only what actually happened and, for a final publish, only after the user did it or said go.
5. Never assume the newest version is live: read `release.py show <game>` or the dashboard first. "not live in: play, apple" means the current version has not reached users there.
