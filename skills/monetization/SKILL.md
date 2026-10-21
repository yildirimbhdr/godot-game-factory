---
name: monetization
description: Add AdMob ads (rewarded, interstitial) and Firebase Analytics to a Godot game from this factory, test them safely and prepare the release. Use when the user asks for ads, AdMob, analytics, Firebase, events, or revenue, and before any store release of a game that has them.
---

# Ads and analytics

Module: `templates/modules/ads-admob/` (read its README first). Decision: `docs/decisions/0015-ads-and-analytics.md`.

## Order of work
1. Ask which formats the user wants (rewarded / interstitial / banner) and whether the AdMob and Firebase accounts exist. No accounts is fine: build and test with Google's test ids, the user fills real ids at release.
   **Firebase is never set up unasked**: the scaffold step asks first, and a "no" means the game keeps the `Analytics` mock.
   On a "yes", set it up with the Firebase MCP tools (load them via ToolSearch): `firebase_get_environment` shows whether the user is
   logged in; if not, call `firebase_login` (it returns a URL and a session id: show both to the user, who signs in and pastes the auth code back; `! firebase login` does not work here, it needs an interactive terminal). Then `firebase_create_project` (or reuse one the user names),
   `firebase_create_app` for iOS (bundle id) and Android (package name), `firebase_get_sdk_config` to write `GoogleService-Info.plist`
   and `google-services.json` into the game root (never into the plugin repo). Confirm the project name with the user before creating it. If creation fails with a project-quota error, do not retry: offer one shared existing project (one app per game; explain the trade-offs from the module README) and let the user pick it and decide about renaming it in the console. `firebase_update_environment` sets the active project before `list_apps`/`create_app`; never touch apps that are already there.
2. Ask before downloading the addons (the user wants to approve installs). Install per the module README into the game.
3. **Design the placement before coding**, write it in the game's brief:
   - Rewarded is always opt-in and visible (a "+" or video icon where the player needs something: extra hint, extra life, double reward). Never forced.
   - Interstitial only at a natural pause (the "Next level" tap), never on a failure, never in the first levels, capped by cadence.
   - Never block the game when an ad is not ready: say so on screen (`No ad ready`) and carry on.
4. Define the events before wiring them (`level_start`, `level_end{success}`, `hint_used`, `rewarded_*`, plus the 2-3 questions the user will ask of the data, e.g. which level people quit on). Use Firebase's recommended names where one exists.
5. Wire the settings screen: copy `common/settings_panel.*` (it has the labelled privacy-options button, shown only where consent applies).
6. Test in this order: headless/playtest with mocks (flow, cadence) -> real device with **test** ads (read the device console with `devicectl ... --console`: look for `success to load RewardedAd` / `interstitial`, UMP lines) -> Firebase DebugView -> only then live ids.

## Hard rules
- Debug builds never request live ads. A real ad unit shown to the developer risks the AdMob account.
- Analytics collects nothing before consent is known; keep the export plugin's privacy-safe defaults on.
- The user's AdMob/Firebase ids and the `GoogleService-*` files stay out of the public plugin repo.
- Do not trust the addon's bundled `skills/*.md`; check function names in `addons/admob/gdscript/src` and the sample tabs.
- `dod_check.py <game> --release` must pass before a store build (empty live ids, test app id).

## Creating the AdMob app and units
AdMob has no usable create API here, so do it in the console with Claude in Chrome (user's signed-in session; ask first, then close the tab):
`admob.google.com/v2/apps/create` (platform, "not in a store", name) then `.../apps/<id>/adunits/create` (format card, unit name
`<game>_<platform>_<purpose>`, leave partner bidding unchecked, default reward 1 Reward). The success page prints the app id (`~`) and
unit id (`/`): copy them from `get_page_text`, never retype. Check the app list first so you never duplicate an app.
Write the ids into `LIVE_UNITS` and the `[admob]` keys; debug builds keep using test units. Remind the user to add the store listing
later (limited ad serving until then).
