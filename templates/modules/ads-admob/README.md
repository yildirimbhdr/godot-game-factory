# ads-admob (AdMob ads + Firebase Analytics)

Real implementations of the `Ads` and `Analytics` autoloads from `godot-base`. Same methods and signals as the mocks,
so game code does not change. Proven on an iPhone SE (Unwind, test ads: consent form flow, SDK init, rewarded and
interstitial both loaded). Android was verified on an emulator (plugins load, Firebase and AdMob initialise); a real Android phone and the Firebase DebugView on Android were not.

## Files
| File | What |
|---|---|
| `ads.gd` | UMP consent -> `MobileAds.initialize` -> preloads rewarded + interstitial; test ids in debug and while `LIVE_UNITS` is empty; interstitial cadence; mutes audio during an ad; privacy-options button support |
| `analytics.gd` | Firebase Analytics wrapper; collects nothing until `Ads.consent_resolved(true)`; prints only off-device |
| `tools/check_ads.gd` | headless check of the interstitial cadence (`godot --headless --path . -s tools/check_ads.gd`) |

## Game API
```gdscript
var granted: bool = await Ads.show_rewarded()      # false: not ready / failed / closed early
Ads.try_interstitial(level_number)                  # once per completed level; cadence is inside
if Ads.try_interstitial(n) and not Ads.is_mock(): await Ads.ad_finished   # before changing scene
Analytics.log_event("level_end", {"level_name": "3", "success": true})
Ads.privacy_options_required() / Ads.show_privacy_options()   # settings button, needed in EEA/UK
```
Defaults in `ads.gd`: interstitial from level 4, every 3rd completed level, never closer than 120 s.
Rule of thumb: rewarded is always opt-in (a visible "+" or video icon); never show an interstitial on a failure.

## Privacy options button
`common/settings_panel.*` shows a labelled "Privacy options" button only when `Ads.privacy_options_required()` is true (EEA/UK) and
opens Google's form. It is a text button on purpose: the entry point must be clearly named. Off-device the mock returns false;
run a playtest with `ADS_FAKE_PRIVACY=1` to see it (`puzzle-unscrew/playtest/privacy.json`).

## Install into a game
1. Copy `ads.gd`, `analytics.gd` into `autoload/` (autoload order: `Ads` before `Analytics`) and `tools/check_ads.gd`.
2. **AdMob** (Poing Studios, MIT, github.com/poingstudios/godot-admob-plugin, release asset `poing-godot-admob-vX.zip`):
   copy `addons/admob`, then unzip `android-template-v<godot>.zip` into `addons/admob/android/bin/` and
   `ios-template-v<godot>.zip` into `addons/admob/ios/bin/` (same Godot version as the editor). Delete
   `addons/admob/{gdscript/sample,csharp,skills,docs}` (the sample scenes import hundreds of files). Enable the plugin
   (`[editor_plugins]` in project.godot). Default app ids are Google's test ids.
3. **Firebase** (godot-x/firebase, MIT, release asset `godotx_firebase.zip`, 73 MB): needs a Firebase project, see below.
   **Android:** run `scripts/setup-android-gradle.sh <game> --firebase`, add an Android preset (Gradle on, `architectures/arm64-v8a=true`,
   `gradle_build/min_sdk="24"`, unique package name, `firebase/android_config_file`, `firebase/enable_core=true`,
   `firebase/enable_analytics=true`), and set the editor's Java path to JDK 17/21 (see `docs/decisions/0002`).
4. Verify on a real device with test ads before anything else (`docs/decisions/0003-first-device-test.md`).

## Firebase setup (needs the user's Firebase project)
- Console: create a project, add an iOS app (bundle id) and an Android app (package name); download
  `GoogleService-Info.plist` and `google-services.json` into the game root. Never commit them to the public repo.
- Copy `addons/godotx_firebase`, `android/firebase_{core,analytics}`, `ios/plugins/firebase_{core,analytics}`
  (skip crashlytics/messaging unless used), enable the plugin.
- Preset options for iOS (written into `export_presets.cfg`): `plugins/GodotxFirebaseCore=true`, `plugins/GodotxFirebaseAnalytics=true`,
  `firebase/ios_config_file="res://GoogleService-Info.plist"`, `firebase/privacy_safe_defaults=true`; exclude filter
  `ios/*,android/*,addons/godotx_firebase/*,build/*,GoogleService-Info.plist,google-services.json`.
- The Firebase MCP (`firebase_create_app`, `firebase_get_sdk_config`) produces both config files. The Android file lists every
  Android app of the project: keep only this game's `client` entry. **Google Analytics must be enabled on the Firebase project**
  (console: Project settings > Integrations). The plist from the Firebase MCP always says `IS_ANALYTICS_ENABLED=false`, even when Analytics works (confirmed for Unwind); judge by DebugView, not by that flag.
- Several games may share one Firebase project (one app per game, filter reports by app). Shared limits: custom dimensions and
  data streams per property; apps cannot be moved to another project later (matters if a game is sold).
- iOS preset (old wording follows): set `Firebase/iOS Config File`, enable Core + Analytics. Android preset: Gradle build, install the build
  template, add the `google-services` classpath/plugin lines from the addon README, enable Core + Analytics.
- Keep **Privacy-safe defaults** on (collection starts off; `analytics.gd` enables it after consent).
- Add `ios/*,android/*,addons/godotx_firebase/*,build/*` to the preset's exclude filter.
- Verify with Firebase DebugView (iOS: launch argument `-FIRDebugEnabled`).

## Release checklist (`dod_check.py --release` enforces the first two)
- [ ] `LIVE_UNITS` in `ads.gd` filled from the AdMob console (rewarded + interstitial, per platform)
- [ ] project.godot `[admob]` keys `general/android/app_id` and `general/ios/app_id` are the real app ids (not `ca-app-pub-3940256099942544~...`)
- [ ] AdMob app registered with the store listing, `app-ads.txt` on the developer website
- [ ] Privacy options button in settings (`Ads.privacy_options_required()`), store privacy labels / Data safety form updated
- [ ] iOS: decide on App Tracking Transparency (needed for personalised ads outside the UMP flow)
- [ ] Never click your own live ads; test devices only

## Notes learned the hard way
- The AdMob addon's bundled `skills/*.md` docs name functions that do not exist (`ConsentForm.load_and_show_consent_form_if_required`).
  The real API is the `gdscript/sample/tabs/*.gd` scenes: `UserMessagingPlatform.consent_information.update(...)` ->
  `UserMessagingPlatform.load_consent_form(...)` -> `form.show(...)`. Read the sample, not the skill docs.
- All AdMob classes are silent no-ops off-device (no plugin singleton), so callbacks never fire in the editor: `ads.gd`
  branches on `OS.get_name()` and uses its own mock there.
- iOS export builds through Swift Package Manager (`admob_spm/`): the first `xcodebuild` needs network.
