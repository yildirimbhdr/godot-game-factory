# 0009 - Unwind pilot log (2026-10-21)

First game built end to end with the factory: `~/Desktop/games/unwind` (brief `ART_BRIEF.md`, assets listed in its `ASSETS.md`).

## What the pilot proved
- Art route: brief -> anchor (screw) -> approved recolour set -> jars, plates, icons, all via `genart.py` under a $3 cap (about $2.3 spent for 28 images, mostly in one-shot batches).
- UI: Kenney casual-green recipe adapted per decision 0008 (pastel palette in `theme_recipe.json`, pause icon from generated art, screw hero on the menu).
- Physics: RigidBody2D plates pinned by PinJoint2D (frozen while 2+ screws hold them), two depth planes by collision layer, covered screws untappable. Verified by scripted playtests of 4 levels plus the tray-full UI path.
- Not automated: the natural "tray full and no move" loss (needs a hand-made level); only the Tray Full screen and retry are tested.

## Plugin changes made because of the pilot
- `playtest_driver.gd`: `tap_group`, `expect_group_count`, `call`, `--shots` direct viewport marks. `playtest.sh`: caffeinate.
- `game_over`: configurable title and optional Next button. `hud`: `set_title`, pause button in group `pause_button`.
- `genart.py`: ledger lock (lesson 0007). Lessons 0007-0009.

## Open for the plugin (not yet done)
- No game-specific SFX for unscrew/jar-full (reused 3 Kenney sounds); audition folder for the user needed.
- The DoD gate is still a checklist, not a hook. `genart.py --size` makes square canvases.
- App icon and store screenshots not made.
