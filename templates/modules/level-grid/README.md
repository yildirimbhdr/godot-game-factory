# level-grid

Level select for level-based games: worlds of 10 levels as a grid of cells (locked / open / cleared, three stars, pulsing current level),
saved progress, star total, home button. Generic: it only needs a `Levels` class with `DATA`, `LEVELS_PER_WORLD`, `WORLD_NAMES`,
`WORLD_COLORS` (see `modules/light-puzzle/levels.gd`) and a `Game` class with a static `level_index`.

- Settings keys: `level_unlocked` (int, default 1), `stars` (Dictionary level index string -> 1..3), both in the base `Settings`.
- Main menu Play opens `SceneTransition.LEVEL_SELECT_SCENE`; the result screen's levels icon returns to it (`GameOver.menu_scene`).
- Playtests: cells are in group `level_cell` (`tap_group`, `expect_group_count`); seed progress with `setting` steps.
- Needs `StarRow` and `GlyphButton` from `modules/common` (the base already contains them).
