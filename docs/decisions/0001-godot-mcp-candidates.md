# 0001 – Godot MCP candidates (tested 2026-10-21, Godot 4.7.2, macOS arm64)

Test project: 540x960 portrait Control scene with one Button and one Label.

| | mkdevkit/godot-mcp | raising-heart/godot-mcp |
|---|---|---|
| Connection | Editor addon + WebSocket (port 6505); editor GUI must be open | Spawns Godot per call over stdio; no addon, no GUI |
| Tools | 173 | 17 |
| Run + screenshot | Worked (`play_scene`, `get_game_screenshot`, base64 only) | Worked (`capture_screenshot`, saved PNG + inline image) |
| Input simulation | Worked (`click_button_by_text`; key/mouse/sequence tools exist, not all tried) | None |
| Output log | Returned empty after button clicks that `print()` | `get_debug_output` (not yet tested after run) |
| Script error check | Not tested | Worked (`check_scripts`) |
| Setup friction | Copy addon into every project, enable plugin, wait for editor reconnect (~8 s) | `npm install` only |
| Activity | Last commit 2026-06-09, 4 commits | Last commit 2026-10-17, 65 commits |
| License | MIT | MIT |

## Follow-up experiment: scripted touch without an MCP

`godot --path P --write-movie out/f.png --fixed-fps 20 --quit-after N -- --playtest=res://scenario.json`
with an inert-by-default autoload (`templates/godot-base/autoload/playtest_driver.gd`) that injects
`InputEventScreenTouch` events from a JSON scenario. Result: 3 scripted taps incremented the counter
(`taps: 3` visible in the captured frame), output is deterministic (fixed fps, frame index logged), and
Movie Maker also writes a `.wav`, so audio presence can be checked automatically.

## Decision

Use **raising-heart/godot-mcp** for project info, script error checks and run/screenshot, and our own
`playtest_driver` + Movie Maker for interaction tests. mkdevkit is not needed for the default workflow
(optional advanced mode later, if live editor control is wanted).

Open: how the plugin installs/builds the MCP server (plan: `doctor` skill does `npm install` on first use).
