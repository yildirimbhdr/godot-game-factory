# fastlane playbook: the stores without Claude (decision 2026-10-26, lesson 0053)

Why: driving App Store Connect and Play Console in Chrome cost far too many tokens. Texts, images and builds are already files, so fastlane uploads
them with one command. Claude's job ends at "the release package is ready"; the user (or a cheap script run) does the rest.

## Google Play: the tested route (scripts/play_publish, 2026-11-20)
Verified on Snake Fill 1.1.0 (AAB uploaded as a production draft with EN+TR notes, no browser). Run from inside the games folder; these replace `fastlane_prepare.py`/`fl.sh` for Android.
- `scripts/play_publish/publish_new.sh <game> [track=internal] [--dry]`: privacy+support site -> Firebase hosting (`_site`), store texts + icon + feature graphic + screenshots -> Play, signed AAB -> Play as a **draft**. Not yet run on a brand-new app record (dry run only); expect small fixes on first real use.
- `scripts/play_publish/publish_update.sh <game> "EN notes" "TR notes" [version] [track=production] [--dry]`: bumps version code/name (and iOS build), builds the AAB, uploads it with release notes as a draft. Texts/images untouched.
- `scripts/play_publish/publish_listing.sh <game>`: refresh only texts/images (needed only when listing text or screenshots change).
- Key: `~/.game-factory/play-service-account.json` (or `$PLAY_JSON_KEY`; the old `keys/` path is also accepted). Never in git.
- **Service account permissions (account level, all apps)**: *Release to production, exclude devices, and use Play App Signing*, *Release apps to testing tracks*, *Manage store presence* **and** *View app information and download bulk reports (read-only)*. Without the last one every upload fails with `403 The caller does not have permission` even though the others are ticked (lesson 0058). Save and allow a few minutes.
- Do not retry a failing upload in a loop (ban risk): fix the cause, then one try.
- A one-off release of an already built AAB: `fastlane supply --json_key $KEY --package_name <pkg> --aab <file> --track production --release_status draft --skip_upload_metadata --skip_upload_images --skip_upload_screenshots`.
- Still manual per new app (no API): create the app in Play Console, privacy URL field, Data safety, content rating, ads declaration, target audience, production countries, and the final "Send for review". `store_declarations.py` has the answers.

## One-time setup (per Mac, ~20 minutes)
1. `scripts/fastlane_setup.sh` prints what is missing and creates `~/.game-factory/fastlane.env` and `~/.game-factory/keys/` (chmod 700).
2. `brew install fastlane`
3. **App Store Connect API key**: appstoreconnect.apple.com > Users and Access > Integrations > App Store Connect API > Team Keys > Generate (role **App Manager**).
   Download `AuthKey_XXXX.p8` once, save it as `~/.game-factory/keys/AuthKey.p8` (chmod 600), put Key ID and Issuer ID into `~/.game-factory/fastlane.env`.
4. **Play service account**: Play Console > Setup > API access (account level) > link or create a Google Cloud project > Create new service account (Google Cloud opens)
   > add a JSON key and download it > back in Play Console grant that account ACCOUNT-level permissions (covers all current and future apps): *Release to production, exclude devices, and use Play App Signing*, *Release apps to testing tracks*, *Manage store presence* and *View app information and download bulk reports (read-only)* (the last one is required, see above). Save the JSON as `~/.game-factory/keys/play-service-account.json` (chmod 600). Allow up to a few hours for it to become active.
5. The upload keystore stays in `~/.game-factory/keystores/` with its password in the macOS Keychain (already used by `android_release.sh`).

## Per game
1. `scripts/store_declarations.py <game> --violence none|cartoon|realistic` writes `store/declarations.md`: the answer to every form no API can fill. ~10 minutes of copy and click per new app (see "Forms that stay manual").
2. Build the release package: `ios_release.sh <game> <work> --upload` (or the `build_upload` lane) and `android_release.sh <game> store/builds/<name>.aab`.
3. `scripts/fastlane_prepare.py <game> --first` (omit `--first` on updates) turns `store/listing.json` and `store/out/` into `<game>/fastlane/` (metadata for both stores, screenshots, Appfile, Fastfile).
4. Upload:
   - `scripts/fl.sh <game> ios metadata`: App Store texts + screenshots (never submits)
   - `scripts/fl.sh <game> android listing`: Play texts + icon + feature graphic + screenshots
   - `scripts/fl.sh <game> android release aab:store/builds/x.aab track:internal`: AAB as a draft on a track (use `track:production` to prepare the production draft)
   - `scripts/fl.sh <game> ios submit` attaches the processed build and submits for review: only when you mean it
5. Record each step with `release.py store <game> play|apple <state>`.

## Forms that stay manual (once per app, in the console)
Apple: create the App ID and the app record (New App), App Privacy answers + publish, age rating questionnaire, content rights, pricing, review contact (needs a phone number).
Google Play: create app (two legal checkboxes), App content declarations (privacy, ads, access, IARC, target audience, data safety, ad ID, government, finance, health), store settings (category, email),
production countries, AI-generated asset labels, and the first AAB upload when the console asks for it. `store/declarations.md` has the exact answers for each. After an app exists, updates are lane runs only.

## Rules
- Run `fastlane_prepare.py` again after any change to the listing or screenshots; it rewrites `fastlane/metadata` and `fastlane/screenshots` and keeps a hand-edited Fastfile.
- The Fastfile never contains secrets: key ids and paths come from `~/.game-factory/fastlane.env`.
- iOS "What's New" is not allowed for version 1.0: `--first` leaves `release_notes.txt` out. Play changelogs go in `metadata/android/<locale>/changelogs/<versionCode>.txt` for updates.
- Locale codes differ: Apple `en-US`, `tr`; Play `en-US`, `tr-TR`. The prepare script maps them.
- Do not edit store pages by hand after a lane run without telling the next run: deliver overwrites with `force: true`.
- If a lane fails on screenshot sizes or locales, read fastlane's message first; do not fall back to the browser unless the user asks.

## Google Play without the browser: ship.sh (0.8)
`scripts/play_publish/ship.sh <game> [--track T] [--notes-en TXT --notes-tr TXT] [--dry]` runs `preflight.py` (definition of done for Android, package names, listing, graphics, live privacy/support pages, app-ads.txt, keys), then `publish_new.sh` or `publish_update.sh` (chosen from `store/status.json`), checks the built AAB (real AdMob app id in the manifest), uploads a draft, records it with `gf_status.py` and prints the steps that stay manual. `store_declarations.py` writes `store/declarations.html` (one page of copyable answers with tick boxes). Every game keeps one `store/status.json` (schema 2, see `scripts/gf_status.py`), which the dashboard reads.
- Account permission: the service account needs "Create, edit, and delete draft apps" as well, or the store listing of a brand-new (never published) app is refused with "The caller does not have permission". The AAB upload works without it.
- `publish_listing.sh` passes `--track` and `--version_code`; supply otherwise fails with "Could not find release for version code ''".
- Godot rewrites `project.godot` when it saves the project and can drop the `[admob]` section; `dod_check.py --release` and the AAB check catch it.
