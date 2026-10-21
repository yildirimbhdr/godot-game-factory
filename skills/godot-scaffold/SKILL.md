---
name: godot-scaffold
description: Start a new 2D mobile Godot game from the factory template (portrait, pause, settings, audio, safe area, themed UI, playtest). Use when the user asks to make a new game or start a game project.
---

# Scaffold a new game

The template is a starting point that is **copied** into the game. It is never a dependency, and it must not make games look alike:
all visual identity comes from the game's own theme and assets.

Paths below are relative to the plugin root (`${CLAUDE_PLUGIN_ROOT}`).

## 1. Brief (ask only what you cannot decide)
Collect, in one short message: game idea and core loop, theme/mood, orientation (default portrait), music wanted (optional, default no),
and **always ask, as a separate yes/no per item (never assume, never skip the question)**: AdMob ads, Firebase Analytics, IAP.
All are optional and default to no; the answer goes into the GDD. On a yes, run the `monetization` skill right after the project is created
(Firebase: it checks the user's `firebase login` and creates the project and apps itself, only the user's login is manual). Write the answers into `<game>/GDD.md` with a "what we will NOT build" list.
Read `lessons/` first: every file there is a mistake that already happened once.

## 2. Create the project
1. Copy `templates/godot-base/` to `<workspace>/<game-slug>/` (never edit the template itself).
2. Set `application/config/name` in `project.godot`; set package/bundle id and Team ID only in the game's own `export_presets.cfg`
   (never commit a Team ID to the plugin repo).
3. Choose the art direction **for this game** (see `asset-pipeline`): build a theme with
   `python3 scripts/build_theme.py <game> data/themes/<recipe>.json` or write a new recipe. Do not ship `FACTORY_DEFAULT`.
4. SFX: edit `assets/audio/sfx.spec.json` (pick sounds that fit the game, vary them from other games), then `scripts/sfx.sh build <game>`.
   Music is optional: `scripts/music.sh add ...`.
5. Run `godot --headless --path <game> --import` twice (first pass loads themes before textures exist).

## 3. Build the game
Replace the placeholder in `game/`. Keep: the `Hud` instance (pause button), `PauseManager.set_gameplay_active(true)` while a run is active,
`SceneTransition` for scene changes, `AudioManager.play_sfx(...)` for every meaningful event, `Haptics`, `Ads` (mock) for any ad call,
`SafeArea` around HUD content, `UIButton` for buttons. Use containers/anchors, not fixed coordinates.
Add juice to every interaction (tween, particles, flash, shake); a static screen counts as unfinished.

### Icon behaviour (lesson 0018)
Icons are controls, not decoration. Audio icons mute/unmute their channel when tapped and show a muted glyph (`IconButton.glyph_off`), vibration shows an off state, the pause button pauses. Test each with a `tap_group` playtest step (`playtest/mute.json` in Unwind is the pattern: tap, `expect_bus_muted`, tap again).

## 5. Publishing
When the Definition of Done passes and the user says the game is ready (or asks about the stores, logo, banner, screenshots, listing), switch to the `store-release` skill. It owns graphics, texts, privacy page, builds and the console work; the profile (`dashboard` skill) supplies the publisher name and public contact email so they are asked only once.

## 4. Verify before saying "done"
Use the `playtest-verify` skill. A game is not finished until its Definition of Done passes.

### Measure pacing before tuning it (lesson 0026)
Before balancing anything, measure time-to-first-death twice: a **no-input** run and a **greedy-bot** run. A casual game that
ends before the player has seen the core mechanic has no clip and no player, so target a run that shows the mechanic at least
twice. Record both numbers in the GDD and tick the pacing row in `DOD.md`.
When a playtest assertion about UI state fails, read the mark screenshot before touching UI code: the game is often simply in a
different state than the scenario assumed (a dead player legitimately does not pause).
