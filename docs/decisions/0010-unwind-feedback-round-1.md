# 0010 - Unwind feedback round 1 and the rebuild (2026-10-21, user on iPhone SE)

User verdict after the first on-device test: (1) font does not match the theme, (2) colours wrong, green disliked, backgrounds flat, settings same, (3) it is a level game and needs a level map, (4) pieces were few, huge and loose; in the genre pieces form a whole (jigsaw / crossing bars), are tight, layered (top pieces first) and each has physics (when its screw goes it drops or slides but other pieces are there).

Changes made:
- Theme: Lilita One (OFL) font, grey Kenney buttons tinted lavender, outlined labels, lavender panels, new `Backdrop` scene (gradient, blobs, faint screws/gear/star drifting) on menu, map and game. `build_theme.py` gained `tint`, local `font` and `label_outline`.
- Puzzle: pieces are code-built polygons (`Figure`: ASCII silhouette -> jigsaw pieces, capsule bars, 0-3 depth planes), `Piece` bodies with pin joints, board with ghost holes, released pieces fade; screws smaller (R 34). 8 levels, saved progress, level map with locked/current/done stops.
- Checks: `tools/check_levels.gd` (rules + random-playout win rates, 43%-100%), playtests on 3 screen shapes, autoplay hook.
- Plugin: skill `physics-puzzle-design`, lessons 0010-0012, art-direction rules, playtest driver steps.
