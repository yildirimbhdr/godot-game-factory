# 0012 - Unwind feedback round 3 (2026-10-21, user)

User asked whether the plugin was updated from their feedback (answer: yes, lessons 0010-0015, skill sections 1-7, decisions 0008-0012, template IconButton/pitch/tap_group), then: tray at the bottom so it is visible, lives on mistakes, and falling pieces that stall mid-fall during fast play (suspected effect).

Done: tray moved to the bottom (figure centre y 1060, board bounds 520-1640); 3 hearts, a mistake (covered screw or nowhere to put it) costs one, Out of Lives screen, lives cap stars; stall fixed by Camera2D shake, cached particle textures/ramp and dirty-flag cover updates. Test: `playtest/lives.json`.

## Greedy shortcut (same day, user)
User: "I only tap the colours of the 2-3 visible jars and I win." Cause: the difficulty metric's "smart" bot was the greedy strategy itself. Fix: `Figure.simulate` has RANDOM / GREEDY / HEURISTIC policies, `Figure.solve` (DFS) proves solvability, `deep_first` queues the deepest-buried colours first, tools search 300 colour deals per level. Greedy win rates now 100% (tutorial), 59, 32, 30, 10, 10, 8, 4%; every level proven solvable. Lesson 0016.
