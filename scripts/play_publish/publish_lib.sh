# shared helpers for publish_new.sh / publish_update.sh / publish_listing.sh (Google Play via fastlane supply, no browser)
# The games folder is the git root of the current directory (or $GF_GAMES, or ~/Desktop/games). Run these from inside it.
HERE_PLUGIN="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_SCRIPTS="$(cd "$HERE_PLUGIN/.." && pwd)"
GAMES="${GF_GAMES:-$(git rev-parse --show-toplevel 2>/dev/null || echo "$HOME/Desktop/games")}"
HERE="$GAMES/_publish"   # work dir only: $HERE/.work/<game>
KEY="${PLAY_JSON_KEY:-$HOME/.game-factory/play-service-account.json}"
[ -f "$KEY" ] || { [ -f "$HOME/.game-factory/keys/play-service-account.json" ] && KEY="$HOME/.game-factory/keys/play-service-account.json"; }
need_key() { [ -f "$KEY" ] || { echo "Play service account JSON missing: $KEY (see skills/store-release/playbooks/fastlane.md)"; exit 1; }; }
game_dir() { [ -d "$GAMES/$1/store" ] || { echo "no such game with a store folder: $1 (looked in $GAMES)"; exit 1; }; echo "$GAMES/$1"; }
pkg_of() { tr -d '[:space:]' < "$1/bundle_id.txt"; }
