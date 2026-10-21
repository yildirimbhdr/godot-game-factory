# game-factory-godot

A Claude Code plugin that turns "make me a game" into a repeatable, **verified** workflow for polished 2D mobile games
(Android and iOS) built with **Godot 4**.

Version 0.3. Proven end to end on macOS with a pilot game (a physics screw puzzle, 32 levels, hints, sound, AdMob test ads and Firebase Analytics) installed on a real iPhone.

## Why

A coding agent left alone ships games with placeholder art, no sound, no animation, no pause button, a first level that
works and nothing else, and "it runs" as the only test. This plugin makes those requirements part of the process and
checks them with scripts instead of trust:

- every mistake that reached a real user is a **lesson** with an enforcing rule (`lessons/`),
- a **Definition of Done gate** (a Stop hook) refuses to let Claude call a game finished until the automated checks pass,
- a deterministic **scripted playtest** drives the game with touches and keeps screenshots of the marked moments.

## What is inside

| Part | What it does |
|---|---|
| `templates/godot-base` | Portrait 1080x1920 starter: menu, pause, settings, game over, safe area, fade transitions, audio manager (limiter, pitch), haptics, mock ads API, `DOD.md`. Neutral look: every game builds its own theme |
| `templates/modules/common` | Reusable pieces proven in the pilot: `GameFx` (floating words, camera shake, confetti, flash, breaking heart), `LivesView`, `IconButton` (toggle glyphs), `Backdrop`, level map with saved progress and stars, icon-only pause/settings/result screens |
| `templates/modules/puzzle-unscrew` | Reference physics puzzle: ASCII silhouettes become jigsaw pieces, depth planes, hidden screws, rigid-body physics, jars and a buffer tray, plus the level tools (rule checker, naive/greedy/solver difficulty analysis, colour-deal search) |
| `templates/modules/ads-admob` | Real `Ads` (AdMob via Poing Studios: UMP consent, rewarded, interstitial with cadence, test ads in debug builds) and `Analytics` (Firebase, collection only after consent) autoloads that replace the base mocks without changing game code; privacy-options button lives in the settings panel |
| `scripts/release.py` | Version bumps (major/minor/patch plus a shared build number), CHANGELOG.md and per-store state (live, in review, in testing); shown on the dashboard |
| `scripts/gf_profile.py`, `dashboard.py` | Your publisher profile (asked once, reused by every game, stays on your machine) and an offline dashboard page with the profile and every game's ids, store assets, listing, privacy page, builds and release progress |
| `scripts/android_release.sh`, `ios_release.sh`, `site_deploy.sh`, `setup-android-gradle.sh` | Signed release AAB (password from the macOS Keychain), App Store archive + upload through your Xcode-signed-in Apple account, one Firebase Hosting site for all your privacy/support pages, Gradle template setup |
| `scripts/store_assets.py`, `store_listing_check.py`, `privacy_policy.py` | Store graphics (icons, Play feature graphic, captioned screenshots per locale and store size), listing text limit checker, bilingual privacy policy page generated from the SDKs the game ships |
| `scripts/playtest.sh` | Movie-Maker playtest: taps, group taps, method calls, expectations, screenshots, audio checks (silence, clipping, missing SFX); records a DoD stamp per screen shape |
| `scripts/dod_check.py`, `hooks/hooks.json`, `scripts/dod_hook.sh` | The Definition of Done gate (see below) |
| `scripts/build_theme.py`, `data/themes/` | 9-slice UI theme from Kenney CC0 packs with recipes (tint, own font, outlined text) |
| `scripts/sfx.sh`, `scripts/music.sh` | SFX from CC0 packs (or retro synth, opt-in), music with loudness normalising, licenses recorded in `ASSETS.md` |
| `scripts/genart.py` | Image generation with the Gemini API for flat/clean 2D art: background keying, trimming, style anchor, 1:1 app icons, **hard credit limit** |
| `scripts/setup-android-gradle.sh` | Prepares a project for Gradle-based Android exports (build template, `.gdignore`, Firebase `google-services` patch); needed by AdMob/Firebase |
| `scripts/setup-godot-mcp.sh` + `.mcp.json` | Installs a pinned Godot MCP server on first use |
| `skills/` | `doctor`, `art-direction`, `godot-scaffold`, `asset-pipeline`, `playtest-verify`, `physics-puzzle-design`, `monetization`, `store-release`, `dashboard`, `lessons-learned` |
| `lessons/`, `docs/decisions/` | What went wrong and why each tool was chosen, with measured results |

## Requirements

- macOS (developed there), Godot 4.x (4.7.x tested), `ffmpeg`/`ffprobe`, `python3` 3.9+, `node` 18+, `git`
- Pillow for image post-processing: `pip3 install --user pillow`
- Android export: export templates, Android SDK, a JDK 17+ set in Godot's Editor Settings
- iOS export: Xcode and an Apple Developer team; the official template has no arm64 simulator, so test on a device
- Optional, for ads/analytics: the Firebase MCP signed in (`firebase_login`), the Claude in Chrome extension signed in to AdMob, an AdMob and a Firebase account (accounts and ids stay in your game, never in the plugin)
- Optional: `GEMINI_API_KEY` in your shell profile for generated art (billing must be enabled for image models), a PixelLab account for pixel art

Run the `doctor` skill after installing; it checks everything and asks before changing anything.

## Install

```
/plugin marketplace add <owner>/<repo>
/plugin install game-factory-godot@<marketplace-name>
```
(Replace with the real repository once it is published.) For local development: `claude --plugin-dir ./game-factory-godot`
and `/reload-plugins`.

## Using it

1. Say what game you want. `art-direction` writes a brief (style, palette, size grid, asset list, what differs from any
   reference game), makes **one anchor asset**, waits for your approval, then generates the set.
2. `godot-scaffold` copies the template, `asset-pipeline` adds theme, font, sounds and music with licenses recorded.
3. Build the game; copy modules from `templates/modules` as needed. Scaffolding **always asks** (separately) about AdMob ads,
   Firebase Analytics and IAP; all are optional, default no. On yes, `monetization` sets everything up: the Firebase MCP creates the
   apps and config files (sign in with its `firebase_login`), Claude in Chrome creates the AdMob app and ad units in your signed-in
   console, and the first test runs on a device with Google's test ads.
4. `playtest-verify` runs the playtests and fills `DOD.md` after Claude has looked at the screenshots.
5. `store-release` prepares everything for the stores (graphics, texts, privacy policy, builds, checklist); you keep the keys, payments and the final submit.

### Credit limit
`genart.py` refuses to run until you set a limit (`genart.py --set-limit 3`) and stops when the next image would exceed it.
Spend is an estimate kept in `~/.game-factory/genart_ledger.json`; the real bill is on your Google AI account. Only you raise the limit.

### Definition of Done gate
While a Godot game was edited in the last two hours, the Stop hook runs `scripts/dod_check.py` and sends the failures back to
Claude instead of letting it stop. Automated checks: game-specific theme and icon, every file listed in `ASSETS.md`, every
`play_sfx("...")` has a sound, strict-audio `smoke*` playtests at three screen shapes newer than the last edit.
If AdMob is installed it also checks that `Ads`/`Analytics` are the real autoloads; `--release` additionally blocks empty live ad
unit ids and Google's test app id.
Manual half: `DOD.md` with no unchecked box and newer than the last edit. Run the check yourself with
`python3 scripts/dod_check.py <project>`.

## Honest limits

- Sound and feel must be confirmed on a real device; desktop playtests cannot hear audio routing or show hitches.
- Difficulty tools measure shortcut strategies and prove solvability, not whether a level is fun.
- Only macOS and Godot 4.7 are tested; Android was verified on an emulator (Gradle build with AdMob and Firebase, logcat), not on a real Android phone.
- Firebase projects have a per-account quota: games may share one project (one app per game); the monetization module README lists the trade-offs.
- Live ads need a store listing in AdMob and its review; until then serving is limited. Debug builds never request live ads.

## License

MIT for the plugin code. Third-party assets keep their own licenses, listed in each game's `ASSETS.md` (Kenney packs are CC0;
fonts and music in the pilot are OFL and CC0).
