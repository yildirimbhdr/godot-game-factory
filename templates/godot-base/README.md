# godot-base

Starting point for every game. It is copied into a new game project, not used as a dependency.

## Layers
1. **Core (`autoload/`)** – no gameplay, no visual identity:
   `Settings`, `AudioManager`, `Haptics`, `Ads` (mock), `SceneTransition`, `PauseManager`, `PlaytestDriver`.
2. **Neutral UI (`ui/`)** – shared behaviour, per-game look. All styling comes from the theme resource
   (`ui/theme_default.tres`, named `FACTORY_DEFAULT`; backgrounds use the `Backdrop` variation). Every game replaces it with its own
   theme; shipping it unchanged fails the Definition of Done. Build one from a recipe:
   `python3 scripts/build_theme.py <project> data/themes/<recipe>.json` (casual-blue, casual-green, fantasy-brown, scifi-blue;
   Kenney CC0 packs, files and licenses recorded in `ASSETS.md`).
3. **Placeholder game (`game/`)** – replace its content, keep the `Hud` instance and the `PauseManager.set_gameplay_active(true)` call.

## Also built in
- `ui/splash.tscn` is the main scene (logo from `assets/art/logo.png`, else the app icon; tap skips); the Godot boot logo is off.
- `Localization` autoload + `assets/i18n/strings.json`: English texts are the keys, language button in settings; formats use `tr("Best %d") % n`.
- `HowTo.show_once(self, "play", "text")`: first-run card, tested by `playtest/howto.json`.

## Rules the template enforces
- Portrait 1080x1920, `canvas_items` + `expand`; build UI with containers/anchors, never fixed coordinates.
- Put HUD elements inside `SafeArea` (48 px minimum margin on every side). Touch targets are at least 150 px (`UIButton`).
- Use `UIButton` instead of `Button`. Use `SceneTransition` instead of `change_scene_to_file`.
- SFX are required, music is optional. Sounds are referenced by name (`AudioManager.play_sfx("score")`, `play_music("menu")`).
  SFX come from `assets/audio/sfx.spec.json` (`scripts/sfx.sh build <project>`: Kenney CC0 packs or pyfxr retro synth);
  music is added with `scripts/music.sh add` (copies the file, measures loudness, records the license).
- Settings always has sliders for music and sound effects; the music slider is hidden automatically if the game has no music.
  A slider at zero mutes its bus (tested in `playtest/smoke.json`).
- Playtests fail on: silent recording, clipping, or a missing SFX (`--lenient-audio` turns that off). Missing music never fails.
- Ads are called through `Ads` only; a real ad module swaps the autoload, game code stays the same.

## Playtest
`scripts/playtest.sh <project> playtest/smoke.json [--resolution 450x975] [--notch] [--lenient-audio]` runs a scripted touch session
and keeps screenshots of the marked moments in `.playtest/<scenario>/marks/`. Exit code 1 on any failed expectation or script error.
