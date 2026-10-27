#!/usr/bin/env bash
# SessionStart hook: put the factory's fixed order in front of the agent before the first prompt,
# so it does not depend on a skill description matching (lesson 0028).
cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"game-factory-godot is installed. When the user asks to make or start a game (or runs /new-game): use the game-start skill, which asks the brief step by step, creates the folder and plan files and then drives the phases. For ideas alone use the game-ideation skill for ideas (many genres, never anchored to the Unwind pilot) and the godot-scaffold skill for building, following its section 0 order: doctor, brief, COPY templates/godot-base, build in Godot scenes/GDScript, show a screenshot of the running game. Never write game logic or simulators in Python. Level-based games need a level select screen; endless games need a high score. Read lessons/ before starting a game."}}
JSON
