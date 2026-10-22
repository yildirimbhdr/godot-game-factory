#!/usr/bin/env bash
# Open the game in a real, visible window so the user can watch (and play) it.
# usage: play.sh <project-dir> [scenario.json] [--resolution WxH]
#   without a scenario: you play it yourself
#   with a scenario:    the scripted taps run in real time on screen (same driver as playtest.sh, no recording)
# Use this to show the user what you are testing. A headless run, a unit script or a simulation is NOT a playtest.
set -euo pipefail
PROJECT="$(cd "$1" && pwd)"; shift
SCENARIO=""; RES=""
while [ $# -gt 0 ]; do
  case "$1" in
    --resolution) RES="$2"; shift 2;;
    *.json) SCENARIO="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"; shift;;
    *) echo "unknown option $1" >&2; exit 2;;
  esac
done
GODOT="${GODOT:-godot}"
if [ ! -d "$PROJECT/.godot/imported" ]; then
  "$GODOT" --headless --path "$PROJECT" --import >/dev/null 2>&1 || true
  "$GODOT" --headless --path "$PROJECT" --import >/dev/null 2>&1 || true
fi
ARGS=(--path "$PROJECT")
[ -n "$RES" ] && ARGS+=(--resolution "$RES")
if [ -n "$SCENARIO" ]; then ARGS+=(-- --playtest="$SCENARIO"); fi
exec "$GODOT" "${ARGS[@]}"
