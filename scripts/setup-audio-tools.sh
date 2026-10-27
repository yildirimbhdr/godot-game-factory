#!/usr/bin/env bash
# Idempotent: create the per-user Python venv with the SFX generator. Prints the venv python path.
set -euo pipefail
VENV="${GAME_FACTORY_CACHE:-$HOME/.cache/game-factory-godot}/venv"
if ! "$VENV/bin/python" -c "import pyfxr" >/dev/null 2>&1; then
  command -v python3 >/dev/null || { echo "python3 is required" >&2; exit 1; }
  python3 -m venv "$VENV" >&2
  "$VENV/bin/pip" install --quiet --disable-pip-version-check "pyfxr==0.3.0" >&2
fi
echo "$VENV/bin/python"
