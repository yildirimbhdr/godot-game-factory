#!/usr/bin/env bash
# Only refresh the store listing (texts, icon, feature graphic, screenshots) of an already published game.
# usage: scripts/play_publish/publish_listing.sh <game-folder>
set -euo pipefail
source "$(dirname "$0")/publish_lib.sh"
G="$(game_dir "$1")"; PKG="$(pkg_of "$G")"; WORK="$HERE/.work/$1"; mkdir -p "$WORK"
python3 "$HERE_PLUGIN/make_metadata.py" "$G" "$WORK/metadata"
need_key
fastlane supply --json_key "$KEY" --package_name "$PKG" --metadata_path "$WORK/metadata" --skip_upload_aab --skip_upload_apk --skip_upload_changelogs
