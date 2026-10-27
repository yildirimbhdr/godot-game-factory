---
description: Start a new mobile game, or resume one. Asks a few short questions step by step, writes the project folder and its plan files, then starts building.
argument-hint: "[idea or game name] (optional)"
---

Invoke the `game-start` skill now and follow it exactly: machine check, idea, scope, art, naming, one summary the user approves, then `scripts/new_game.py --brief`.
If the current folder (or the folder the user names) already holds a game with a `PLAN.md`, resume that game instead of starting a new one.

The user said: $ARGUMENTS
