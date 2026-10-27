---
name: game-ideation
description: Come up with game ideas for the factory. Use when the user asks for a game idea, "bir oyun fikri bul", what to build next, or has no concrete idea yet. Never anchored to the pilot game.
---

# Game ideation

The pilot (Unwind, a screw puzzle) is a proof of the workflow, **not** a genre to repeat. Do not propose it, its variants, or
"like Unwind but ..." unless the user asks. `physics-puzzle-design` applies only if the user picks a physics/layer puzzle.

## Process
1. Read the user's constraints (genre they like, session length, art mood, level-based or endless). Ask nothing else.
2. Propose **6 ideas from at least 5 different families**, so the user is choosing between genres, not skins:
   one-tap arcade/reflex, endless runner/dodger, merge/2048-likes, stacking/timing, match-3/sort puzzles, idle/incremental,
   snake/maze/grid, slingshot/aim-and-shoot, word/trivia. Mix in at most one physics puzzle.
3. For each idea, in 4 lines: **hook** (one sentence), **core loop** (what the thumb does every second), **structure**
   (levels with a level map, or endless with a high score), **why it is not a clone** (the one original twist), and
   **scope** (fits 1-2 weeks, no networking, 2D).
4. Prefer ideas whose first 30 seconds explain themselves and whose run lasts 1-3 minutes (see lesson 0026).
5. Recommend one and say why. When the user picks, hand over to `godot-scaffold` (brief, then project).
6. Working titles must not name the first world or character (no "Ice ...", "Penguin ..."); see lesson 0042 and `store-release` (Naming and ASO).

## Pacing of new mechanics
One new thing at a time, then five levels to get used to it: the first 5 levels teach only the core move; boxes arrive at level 6, patrolling monsters at 11, fire turrets at 16, twin-shot turrets at 21 (Slide Buddies, 40 levels), each with a one-time short info card (about 10 words, `HowTo.show_once`). Levels keep getting longer, more tangled and harder after the last introduction; plan 40+ levels, not 15. The first-run tutorial teaches the core move only. Keep the character at or above the screen middle so the thumb stays clear of the bottom buttons (lesson 0055). A rewarded "continue" after a fatal move is offered once per try, restores the state before the fatal move and logs `continue_offered` / `continue_used` (lesson 0054).
