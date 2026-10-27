# 0020 Slide-maze levels: reachable rewards, labyrinth generation, real-time patrols

Status: accepted (2026-10-22, Slide Buddies, user feedback)

**Problems found by the user while playing:** (1) fish/stars in cells nobody can reach or only reach by dying, (2) levels were one winding path, (3) turn-based monsters ("they only move when I move") felt dead.

**Decisions**
- **Reachability pass:** the factory finds every cell the player can pass or stand on (`SlideLogic.analyze()`); collectibles only go on safely passed cells, unreachable floor becomes rock, dead-end hazard tunnels keep no rewards (lesson 0036).
- **Labyrinth by construction:** plan the solution first (each slide carves its corridor and locks the wall beyond the stop), then plan more slides out of known stops for branches/loops, add rooms and hazard dead ends; the solver confirms every star is collectable in one run.
- **Patrols are real-time**, also while the player stands still. They are fair because: patrols never cover a cell the player can stop on (waiting is always safe), the solver accepts a slide when SOME start moment is safe (stricter hit radius than the game), and the factory places a patrol in a side alcove that CROSSES a pass-through cell of the optimal route. A patrol walking along the player's own corridor is unavoidable and was rejected by the solver (this is why the first placement attempt found none).
- The walking line of a patrol is drawn as a faint red trail so the danger can be read.

**Why not turn-based:** it keeps the solver exact but the world stops when the player stops, which the user rejected as lifeless.
