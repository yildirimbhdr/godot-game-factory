# game-factory-godot

Tell Claude Code "make me a game" and get a **finished-looking 2D mobile game** (Android and iOS) built with Godot 4:
your own splash, menu, settings, sounds, effects and (for level games) a level map, tested by actually playing it on screen.

Version 0.4. Proven end to end on macOS with a pilot game (a physics screw puzzle, 32 levels, hints, sound, AdMob test ads and Firebase Analytics) installed on a real iPhone.

## Install

```
/plugin marketplace add yildirimbhdr/godot-game-factory
/plugin install game-factory-godot@game-factory
```
Restart Claude Code, then say **"run the doctor"**: it checks Godot, ffmpeg, node and python and asks before fixing anything.
Update later with `/plugin` > Marketplaces > update, then restart.

## Try it

Just talk to Claude:

| You say | What happens |
|---|---|
| "Bana oyun fikri bul" / "give me game ideas" | `game-ideation`: 6 ideas from different genres (not one genre), each with hook, core loop, level-or-endless, and what makes it original |
| "Make this one" | `godot-scaffold`: short brief (ads/analytics/IAP asked one by one), project created from the template, art direction and theme |
| (while it builds) | You watch Godot open and the game being played; screenshots are checked, not just "it compiles" |
| "Is it ready?" | Definition of Done gate: it cannot say "done" until splash, sounds, pause, 3 screen shapes, assets list and review pass |
| "Publish it" | `store-release`: icons, screenshots, listing text, privacy page, signed builds; you keep keys, payments and the final submit |

## What every game gets (already in the template)

- **Splash screen** with your logo and name (no Godot logo), then main menu, pause, settings, game over, retry
- **Turkish and English** built in (device language, switchable in settings); add more languages in one JSON file
- **First-run how-to card** shown once
- **Sound effects and optional music** with licenses recorded, volume sliders, mute toggles
- **Juice**: button feedback, fades, floating words, confetti, shake, haptics
- **Safe-area aware UI** for notches, touch targets of 150 px or more, auto-pause when the app goes to the background
- **Levels or endless**: level map with saved progress and stars, or a saved high score
- **Optional**: AdMob (consent, rewarded, interstitial) and Firebase Analytics, switched on without changing game code
- **Scripted playtests** that tap through the game and keep screenshots, plus `play.sh` to watch it live

## Why it is different

A coding agent left alone ships placeholder art, no sound, no animation, no pause button, one level and "it runs" as the only test.
Here the rules are enforced instead of trusted:

- every mistake that reached a real user is a **lesson** with an enforcing rule (`lessons/`),
- a **Definition of Done gate** (a Stop hook) refuses to let Claude call a game finished until the automated checks pass,
- a **session hook** reminds Claude of the fixed order (doctor, brief, template, Godot scenes, visible test) at every start,
- a deterministic **scripted playtest** drives the game with touches and keeps screenshots of the marked moments.

## Requirements

- macOS (developed there), Godot 4.x (4.7.x tested), `ffmpeg`/`ffprobe`, `python3` 3.9+, `node` 18+, `git`
- Pillow for image post-processing: `pip3 install --user pillow`
- Android export: export templates, Android SDK, a JDK 17+ set in Godot's Editor Settings
- iOS export: Xcode and an Apple Developer team; the official template has no arm64 simulator, so test on a device
- Optional, for ads/analytics: the Firebase MCP signed in (`firebase_login`), the Claude in Chrome extension signed in to AdMob, an AdMob and a Firebase account (accounts and ids stay in your game, never in the plugin)
- Optional: `GEMINI_API_KEY` in your shell profile for generated art (billing must be enabled for image models), a PixelLab account for pixel art

Run the `doctor` skill after installing; it checks everything and asks before changing anything.

## Useful commands

```
python3 scripts/new_game.py <slug> "<Title>" --dest <folder>   create a game from the template
scripts/play.sh <game> [playtest/smoke.json]                    open the game in a visible window (play it or watch a scripted run)
scripts/playtest.sh <game> playtest/smoke.json                  recorded playtest with screenshots (also run at 450x975 --notch and 600x800)
python3 scripts/dod_check.py <game>                             what is still missing before "done"
```

## Reference: what is inside

| Part | What it does |
|---|---|
| `templates/godot-base` | Portrait 1080x1920 starter: menu, pause, settings, game over, safe area, fade transitions, audio manager (limiter, pitch), haptics, mock ads API, `DOD.md`. Splash, localization (EN/TR), first-run how-to card. Neutral look: every game builds its own theme |
| `templates/modules/common` | Reusable pieces proven in the pilot: `GameFx` (floating words, camera shake, confetti, flash, breaking heart), `LivesView`, `IconButton` (toggle glyphs), `Backdrop`, level map with saved progress and stars, icon-only pause/settings/result screens |
| `templates/modules/puzzle-unscrew` | Reference physics puzzle: ASCII silhouettes become jigsaw pieces, depth planes, hidden screws, rigid-body physics, jars and a buffer tray, plus the level tools (rule checker, naive/greedy/solver difficulty analysis, colour-deal search) |
| `templates/modules/ads-admob` | Real `Ads` (AdMob via Poing Studios: UMP consent, rewarded, interstitial with cadence, test ads in debug builds) and `Analytics` (Firebase, collection only after consent) autoloads that replace the base mocks without changing game code; privacy-options button lives in the settings panel |
| `scripts/release.py` | Version bumps (major/minor/patch plus a shared build number), CHANGELOG.md and per-store state (live, in review, in testing); shown on the dashboard |
| `scripts/gf_profile.py`, `dashboard.py` | Your publisher profile (asked once, reused by every game, stays on your machine) and an offline dashboard page with the profile and every game's ids, store assets, listing, privacy page, builds and release progress |
| `scripts/android_release.sh`, `ios_release.sh`, `site_deploy.sh`, `setup-android-gradle.sh` | Signed release AAB (password from the macOS Keychain), App Store archive + upload through your Xcode-signed-in Apple account, one Firebase Hosting site for all your privacy/support pages, Gradle template setup |
| `scripts/store_assets.py`, `store_listing_check.py`, `privacy_policy.py` | Store graphics (icons, Play feature graphic, captioned screenshots per locale and store size), listing text limit checker, bilingual privacy policy page generated from the SDKs the game ships |
| `scripts/new_game.py`, `scripts/play.sh` | One-step project creation from the template; open the game (optionally a scripted run) in a visible window |
| `scripts/playtest.sh` | Movie-Maker playtest: taps, group taps, method calls, expectations, screenshots, audio checks (silence, clipping, missing SFX); records a DoD stamp per screen shape |
| `scripts/dod_check.py`, `hooks/hooks.json`, `scripts/dod_hook.sh` | The Definition of Done gate (see below) |
| `scripts/build_theme.py`, `data/themes/` | 9-slice UI theme from Kenney CC0 packs with recipes (tint, own font, outlined text) |
| `scripts/sfx.sh`, `scripts/music.sh` | SFX from CC0 packs (or retro synth, opt-in), music with loudness normalising, licenses recorded in `ASSETS.md` |
| `scripts/genart.py` | Image generation with the Gemini API for flat/clean 2D art: background keying, trimming, style anchor, 1:1 app icons, **hard credit limit** |
| `scripts/setup-android-gradle.sh` | Prepares a project for Gradle-based Android exports (build template, `.gdignore`, Firebase `google-services` patch); needed by AdMob/Firebase |
| `scripts/setup-godot-mcp.sh` + `.mcp.json` | Installs a pinned Godot MCP server on first use |
| `skills/` | `doctor`, `game-ideation`, `art-direction`, `godot-scaffold`, `asset-pipeline`, `playtest-verify`, `physics-puzzle-design`, `monetization`, `store-release`, `dashboard`, `lessons-learned` |
| `lessons/`, `docs/decisions/` | What went wrong and why each tool was chosen, with measured results |

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
