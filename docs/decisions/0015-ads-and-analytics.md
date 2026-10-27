# 0015 - AdMob ads and Firebase Analytics as one module

Date: 2026-10-21. Status: AdMob verified on iOS device with test ads; Firebase written but unverified (no Firebase project yet).

**Decision**
- AdMob via Poing Studios `godot-admob-plugin` v5.1.0 (MIT; Godot 4.7.2 templates exist for both platforms).
- Analytics via `godot-x/firebase` 3.1.0 (MIT; native Firebase iOS 12.16 / Android SDKs; privacy-safe defaults).
- Both stay behind the stable `Ads` / `Analytics` autoloads in `godot-base` (mocks); `templates/modules/ads-admob` swaps in real code.
- Ad formats: rewarded (opt-in, extra hint) and interstitial (cadence-limited); no banner for now (user choice).
- Debug builds and builds without live ad unit ids show Google's TEST ads only; `dod_check.py --release` blocks empty live ids / test app id.
- Consent first: UMP form -> SDK init; Firebase collection starts off and is enabled only when consent is granted or not required.

**Why not others:** mediation adapters and other ad SDKs add review/privacy surface; one network is enough for a pilot.
Firebase has no official Godot plugin; godot-x is the maintained modular one covering both platforms.

**Verified:** device log on iPhone SE: UMP ran, `MobileAds` init, interstitial and rewarded loaded. Mock flow and cadence under playtest.
**Not verified:** Android build, Firebase (needs the user's project + config files), live ad units, real consent form in EEA.

**Addendum (user decision, same day):** Firebase and AdMob are optional per game, but the scaffold step must always ask first
(separate yes/no each). On yes, Claude creates the Firebase project/apps through the Firebase MCP; only the browser sign-in is manual.

**Addendum 2 (2026-10-21):** the user's Firebase account hit the project quota (`firebase_create_project` fails), so all games share
one existing Firebase project (one app per game; the user renamed it to a games-wide name in the console, Claude cannot do that without a
gcloud login). Unwind got an iOS and an Android app in it.
Existing apps in that project were not touched. `firebase login` does not work through `!` (non-interactive); use the MCP `firebase_login`.

**Addendum 3 (2026-10-21): AdMob app and units created by Claude through the AdMob web console** (Claude in Chrome, the user's signed-in
session; the AdMob API cannot create these without a separate OAuth login). Unwind: iOS and Android apps (listed as "not in a store yet"),
one rewarded and one interstitial unit per platform, named `unwind_<platform>_rewarded_hint` / `unwind_<platform>_interstitial`.
Ids live in the game's `autoload/ads.gd` (`LIVE_UNITS`) and `project.godot` (`[admob]`), never in the plugin. Debug builds still use Google's test units.
New apps serve limited ads until a store listing is added in AdMob (`Mağaza ekle`) and the review passes.
