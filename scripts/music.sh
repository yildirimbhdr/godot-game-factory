#!/usr/bin/env bash
# usage: music.sh add <project> <name> <file-or-url> --author NAME --license CC0 [--source-url URL]
set -euo pipefail
[ "${1:-}" = "add" ] || { echo "usage: music.sh add <project> <name> <file-or-url> --author A --license L" >&2; exit 2; }
shift
exec python3 "$(cd "$(dirname "$0")" && pwd)/add_music.py" "$@"
