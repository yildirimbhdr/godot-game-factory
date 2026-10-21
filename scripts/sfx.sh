#!/usr/bin/env bash
# usage: sfx.sh build <project> | sfx.sh audition <project> <name> [--count N]
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
PY="$("$HERE/setup-audio-tools.sh")"
exec "$PY" "$HERE/generate_sfx.py" "$@"
