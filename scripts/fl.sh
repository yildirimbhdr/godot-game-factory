#!/usr/bin/env bash
# Run a fastlane lane for a game with the keys loaded from ~/.game-factory/fastlane.env.
# usage: fl.sh <game-dir> <platform> <lane> [key:value ...]     e.g. fl.sh ../slide-buddies ios metadata
set -euo pipefail
GAME="$(cd "$1" && pwd)"; shift
[ -f "$HOME/.game-factory/fastlane.env" ] && source "$HOME/.game-factory/fastlane.env"
export GF_PLUGIN="$(cd "$(dirname "$0")/.." && pwd)"
cd "$GAME" && fastlane "$@"
