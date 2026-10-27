#!/usr/bin/env bash
# Idempotent: fetch and build the pinned godot-mcp server into a per-user cache.
set -euo pipefail

REPO="https://github.com/raising-heart/godot-mcp"
COMMIT="a9efd969f67dea090e1ec066e6d27580f350afe5"
DEST="${GAME_FACTORY_CACHE:-$HOME/.cache/game-factory-godot}/godot-mcp"

if [ -f "$DEST/build/index.js" ] && [ "$(git -C "$DEST" rev-parse HEAD 2>/dev/null)" = "$COMMIT" ]; then
  echo "$DEST/build/index.js"
  exit 0
fi

command -v node >/dev/null || { echo "node (18+) is required" >&2; exit 1; }
command -v git  >/dev/null || { echo "git is required" >&2; exit 1; }

rm -rf "$DEST"
mkdir -p "$(dirname "$DEST")"
git clone --quiet "$REPO" "$DEST" >&2
git -C "$DEST" checkout --quiet "$COMMIT" >&2
(cd "$DEST" && npm install --no-audit --no-fund >&2)
echo "$DEST/build/index.js"
