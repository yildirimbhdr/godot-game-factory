---
name: physics-puzzle-design
description: Design rules and checks for physics/layer puzzle games (unscrew, pull-pin, stacking, sliding pieces). Use before building any game where pieces form a picture, hold each other, or fall and collide, and whenever the user shares a reference screenshot of such a game.
---

# Physics / layer puzzle design

Born from the Unwind pilot (decision 0010). The first version was rejected because it had a few big plates, no levels and no real "held together" feeling. Check every item below **before** writing code.

## 1. Read the reference screenshot properly
A screenshot is not only a mechanic. Write down, in the brief, each of these (and show the user):
- **Structure:** level number, level map or list, progress, lives/timer, buffer slots. A game with "Level 32" on screen is a level game: it needs a level map and saved progress.
- **Piece density:** how many pieces, how big relative to the board (many small pieces, tight against each other, not 3 large ones).
- **Whole picture:** do the pieces assemble into a figure (rocket, guitar, heart) or a pattern (crossing bars)? Plan 8+ distinct silhouettes.
- **Layers:** which pieces sit on top of which. Hidden fasteners must not be reachable until the piece above is gone.
- **What differs in our version** (look, names, layout): never copy the reference's UI or art.

## 2. Pieces must tile or cross exactly
- Generated art (Gemini/PixelLab) cannot produce pieces that fit each other. Build puzzle pieces as **polygons in code** (grid cells merged into polyominoes, or capsule bars between two points), drawn in the game's style (thick outline, glossy edge, soft shadow, holes where fasteners were). Collision polygon = the drawn polygon, so physics matches what the player sees.
- Same-plane pieces keep a small gap (4-6 px) so they never overlap; overlapping pieces must be in different planes.
- Auto-split silhouettes (ASCII mask -> jigsaw pieces) so adding levels is cheap; colour neighbours differently.
- Fastener colour must contrast with piece colour: saturated fasteners on pastel pieces.

## 3. Physics rules (RigidBody2D)
- Pin joints per fastener to a static anchor. Keep a piece frozen while 2+ fasteners hold it; unfreeze at 1 (it swings on the last one) and 0 (it falls).
- Planes = collision layers. A piece collides only with its own plane; a fastener is tappable only if no piece in a higher plane **that still has fasteners** covers it. Released pieces must not block or cover anything: fade them out after ~1.5 s and free them when off screen.
- Tween callbacks on pieces that can be freed: create the tween from the piece itself (`piece.create_tween()`), otherwise "lambda capture was freed" errors appear.
- Taps: use `event.position`, not `get_global_mouse_position()` (lesson 0009).

## 4. Levels
- Data-driven (`levels.gd`), deterministic (`seed`), total fastener count a multiple of the container capacity, every colour a multiple of it.
- **Check solvability headlessly** (`tools/check_levels.gd`): geometry rules (min fastener spacing, figure inside the board area, no piece with <2 fasteners) plus a random-playout solver with a win rate per level. A level with 0% wins is rejected. Rising difficulty = more colours, more planes, lower win rate.
- Board area must clear the HUD/buffer rows on tall and short screens (centre the board when the viewport expands).

## 5. Around the game
- Level map with locked/current/done states, saved progress (`Settings`), win -> Next / Replay / Levels.
- Playtest hooks: group-based taps (`tap_group`), an `autoplay_step` the game exposes for `call`, `UNWIND_LEVEL`-style env var to start at any level. Run all levels, not just the first.
- Look at screenshots of **every** level at the tight and the tall resolution before reporting.

## 6. A puzzle must make the player think (second Unwind round)
The first level set was rejected: every screw could simply be removed in any order. Rules:
- **Hidden fasteners.** Place fasteners of back pieces under pieces in front (cap about 3 per covering piece so the front piece keeps room for its own). Only 40-65% of fasteners may be open at the start (`check_levels` enforces it from level 2).
- **Pressure.** Few visible containers (2 jars from level 2), a small buffer (5 slots), 5-6 colours in later levels. A buffer that never fills is not a rule.
- **Measure thinking with the player's shortcut, not a random bot.** The user spotted that tapping only screws that match the visible jars wins the game. Simulate that GREEDY player (plus a random one) and require: tutorial about 100%, then falling to a few percent in late levels, AND a depth-first search that proves a winning order exists (`Figure.solve`). A "smart" heuristic bot that is really the greedy player proves nothing (round 3 mistake, lesson 0016).
- **Make greedy fail structurally:** queue the colours whose screws are buried deepest FIRST (`deep_first`), so the visible containers ask for screws the player cannot reach yet and the buffer must be managed. Then search colour deals (`design_levels.gd` + `apply_design.py`) for the greedy rate you want and store `color_seed`.
- **Spacing.** Fastener heads 68 px, centres at least ~100 px apart (even across pieces); fewer fasteners per piece (2-3). Dense levels were the user's second complaint.
- **Reward loop (dopamine).** Rising pitch per consecutive direct move, praise words at combo 3/5/8/12, confetti and board shake on every container, small sparkle on every landing, progress bar with a star, release thud and dust when a piece falls, confetti rain plus a 1-3 star rating that pops in one by one on level clear, stars saved and shown on the level map, pulsing play button. A silent, effect-less success is unfinished.
- **Icons, not words,** on pause, settings and result screens (play, restart, gear, home, speaker, vibrate, star); keep text only for titles and numbers. Use `IconButton` (template) and groups for playtests.

## 7. Layout, mistakes and smoothness (third Unwind round)
- **Thumb zone:** the buffer/tray goes at the bottom of the screen where it stays visible and near the thumb; containers and HUD on top, board in the middle. Re-check the board bounds when moving rows.
- **Mistakes cost something:** 3 lives per level; tapping a covered fastener or a fastener with nowhere to go loses a life (0.45 s cooldown against double taps), with heart break, red flash, shake, haptic and a "-1" pop. Out of lives is its own result screen; every lost life caps the star rating.
- **Never shake the parent of physics bodies.** Moving a Node2D that holds RigidBody2D children overwrites their transforms every frame and falling pieces stall mid-air. Shake with `Camera2D.offset` instead, and convert tap positions with the canvas transform.
- **Effects must not allocate in the hot moment:** build gradient textures, colour ramps and particle resources once; recompute cover tests only when a screw was removed or a piece with fasteners is moving.

## 8. Container colours must read as the fastener colours
Recolouring a generated container with `--ref` drifted (the "lavender" jar came out light blue, the coral jar had a lilac face), so purple screws seemed to go into a blue box. After generating a coloured set, put each container next to a swatch of the exact fastener colour (contact sheet) and fix mismatches with an HSV remap (shift hue of the wrong-hued pixels, keep the dark outline); it is free and exact. Keep the originals in the audition folder.

## 9. Variety and help (round 6)
- **Worlds:** a world is 8 levels with its own backdrop gradient, blobs, board colours and map colour (`Levels.WORLDS`, `Backdrop.set_palette`); the map shows a banner per world. Four worlds already stop 32 levels from looking identical; keep text readable on the darkest one.
- **Per-level knobs for variety:** `tray` (2-4), `jars_visible` (1-3), `colors` (3-6), piece size range, bar pattern, silhouette. Put a breather (tray 4, 3 visible jars) before a hard run, and a tight level (tray 2 or 1 visible jar) as a spike, then let the checker prove each is solvable.
- **Hints from the solver:** the level solver can start from the live position (`Figure.solve(..., state)` with alive mask, pieces' remaining screws, jar fill including reserved slots, queue index, tray counts) and return a winning order; ring the first screw of it. 3 hints per level, button bottom right with a counter; if the live position has no solution say "Stuck! Restart". Only allow it while nothing is in flight.
- **Cheap level production:** `tools/new_levels.py` generates variants of an ASCII silhouette (partition seed x bar pattern x piece size), probes them headlessly (`tools/probe_levels.gd`) against the geometry rules, appends the first passing one to `levels.gd`; then `apply_design.py <n>` searches the colour deal. 14 levels took about ten minutes this way.
