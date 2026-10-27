# Modules (copy what a game needs)

`templates/godot-base` is the bare starting point. These modules come from the Unwind pilot and are tested
there; copy files into the game (never make the game depend on the plugin) and read the header comment of each.

## common/
| File | What it gives | Needs |
|---|---|---|
| `game_fx.gd` (`GameFx`) | floating words, camera shake, sparkle burst, confetti (and rain), full-screen flash, breaking heart; resources cached | a `Camera2D` and a Node2D to hold effects |
| `lives_view.gd` (`LivesView`) | hearts row, `lose()` returns hearts left | - |
| `icon_button.gd` (`IconButton`) | square icon button, `glyph`/`glyph_off` toggle, `group_name` for playtests | `UIButton` from the base |
| `backdrop.gd/.tscn` | gradient + blobs + faint drifting icons; edit `ICONS` | icon textures |
| `level_map.gd/.tscn`, `level_node.gd` | winding level map with locked/current/done stops and stars | a `Levels.DATA` array (`name` per level), `Game.level_index` static var, `Settings` keys `level_unlocked`, `stars` |
| `settings_panel.*`, `pause_menu.tscn`, `game_over.*` | icon-only pause/settings/result screens with mute toggles and star rating; settings also holds the labelled privacy-options button (shown only where consent applies, needs `Ads`) | the icon assets under `assets/art/icons/` (play, restart, gear, home, sound_on/off, music_on/off, vibrate, star, star_empty, back) |

Settings keys to add to `autoload/settings.gd` DEFAULTS: `level_unlocked`, `stars`, `music_volume_before_mute`, `sfx_volume_before_mute`.
`AudioManager.play_sfx(name, jitter, pitch)` takes a pitch (template has it).

## puzzle-unscrew/
Reference implementation of a physics puzzle (screws, plates, jars, tray, lives, level map): `figure.gd` (ASCII silhouette ->
jigsaw pieces, bars, hidden-screw placement, solvers), `piece.gd`, `screw.gd`, `jar.gd`, `levels.gd`, `game.gd/.tscn`,
`tools/` (level checker, colour-deal search, `apply_design.py`) and the playtest scenarios. Rules behind it:
`skills/physics-puzzle-design`. Run the checker with `godot --headless --path . -s tools/check_levels.gd`.

## light-puzzle/ and level-grid/
`light-puzzle` is the Prism Path reference (beams, mirrors, colours, mixers, splitters, filters, solver, level factory, 60 levels);
`level-grid` is the generic level select it uses. Read each folder's README. New in `common/`: `star_row.gd` (three code-drawn stars, pop-in with rising pitch),
`glyph_button.gd` (icon buttons drawn in code: undo, restart, hint, home, play, next, gear, levels, back, vibrate; the text stays for tests but is not drawn),
`backdrop.gd` (navy gradient with drifting specks, static under playtests). The base `ui/` now has the icon-only pause, result and settings screens.

`glyph_icon.gd` is the picture-only twin of `GlyphButton`; `star_row_sprite.gd` draws sprite stars with a bounce, turning light rays and a sparkle burst;
`status_bar.gd` is the world / moves / star-goals pill. The base `ui/` menu, HUD and settings are icon-first (gear, play, power, pause, speaker, globe).

## ads-admob/
Real `Ads` (AdMob: UMP consent, rewarded, interstitial with cadence) and `Analytics` (Firebase, consent-gated) autoloads that
replace the mocks in `godot-base` without changing game code. Install steps, Firebase setup and the release checklist are in
`ads-admob/README.md`; decision in `docs/decisions/0015-ads-and-analytics.md`. Check with `godot --headless --path . -s tools/check_ads.gd`.
