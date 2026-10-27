# light-puzzle (reference module, from Prism Path)

Mirror-and-beam puzzle: tap mirrors to flip `/` <-> `\` so beams reach crystals. Colours, mixers, splitters and filters are
built in. Copy the files into a game made from `godot-base` (never make the game depend on the plugin).

| File | What it is |
|---|---|
| `optics.gd` (`Optics`) | Pure logic: `trace(level, kinds)` (segments, which crystals are open), `solve(level, kinds)` (fewest taps by search over mirror states, plus the winning kinds for hints). Splitter loops are cut by a pass-wide visited set |
| `board.gd` (`Board`) | Draws the level, handles taps (`event.position`, lesson 0009), undo history, hint ring, beam draw-in on an additive child layer. `fx = 0` makes everything instant for playtests |
| `levels.gd`, `levels_data.gd` | Level API (worlds, stars) and the 60 generated levels |
| `game.gd`, `game.tscn` | Level scene: moves/par, undo, restart, hint (3 per level), saved stars and unlock, win screen with Next / Replay / Levels, playtest hooks `tap_mirror`, `tap_hint`, `autosolve`, `start_autoplay`, env var `PRISM_LEVEL` |
| `tools/gen_levels.gd` | Level factory: carves light paths from the solution, lets paths share mirrors (this is what makes the puzzle), scrambles, then keeps a candidate only if it meets the world's par and shortcut limits |
| `tools/check_levels.gd` | Every level solvable and not solved at the start |
| `playtest/smoke.json`, `all_levels.json` | Full flow scenario and the state-driven play-through of all levels |

Run: `godot --headless --path . -s tools/check_levels.gd`, regenerate with `-s tools/gen_levels.gd` (about 3 minutes for 60 levels; `-- --only=N` for one).
Needs from the base: `Settings` keys `level_unlocked` and `stars`, `SceneTransition.LEVEL_SELECT_SCENE`, the `level-grid` module, `StarRow`,
`GlyphButton`, `HowTo`, and SFX named `mirror_flip crystal undo hint locked star win score`.

## Screens
`game.tscn` has a status pill (`common/status_bar.gd`: world name, moves / par, three star goals that go dark as moves run out) anchored to the safe
area, a framed board (world-coloured border, corner brackets, dots in empty cells) placed below the pill, and a buttons dock. `ui/game_over.gd` is the
framed level-clear screen (gem, world progress pips from `ui/world_progress.gd`, count-up, Perfect / New best badges, one shine sweep); copy it over the
base `ui/game_over.gd` and pass the `extra` dictionary (see `game.gd`). Beams follow a flipped mirror at once; the draw-in plays only when a level starts.

## Juice included (the dopamine loop)
Spark on every flip, per-colour burst and ring when a crystal lights (pitch rises per crystal), "Double! / Triple! / Wow!" for several crystals in one flip,
screen flash + shake + confetti rain + "Nice! / Great! / Perfect!" on a clear, a streak of consecutive par clears (`Settings` key `streak`), world-complete
confetti, a bounce-and-ring pop for the newly unlocked level (`just_unlocked`), and ambient life (breathing lamps, twinkling crystals, shimmering beams).
All of it is skipped when `fx = 0` (playtests). `GameFx` and `Backdrop` (optional world image with `dim`) live in `modules/common`.

## Lessons that shaped it
- Independent paths are solved one by one even when each is hard; **sharing a mirror between two beams** couples them (0013, 0016).
- Measure the shortcut with a bot that taps only mirrors the beam touches, per level, and tune thresholds per world (see the table in a game's GDD).
- Generation bugs that only the solution check catches: always trace the unscrambled solution before scrambling.
