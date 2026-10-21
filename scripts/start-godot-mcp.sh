#!/usr/bin/env bash
# MCP entry point: make sure the server is built, then run it on stdio.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ENTRY="$("$HERE/setup-godot-mcp.sh")"
exec node "$ENTRY"
