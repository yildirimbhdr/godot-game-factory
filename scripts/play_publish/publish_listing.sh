#!/usr/bin/env bash
# Only refresh the store listing (texts, icon, feature graphic, screenshots) of an already uploaded game.
# usage: scripts/play_publish/publish_listing.sh <game-folder> [track]
# The track and version code are always passed to supply: without them fastlane tries to update a changelog for version code '' and fails.
set -euo pipefail
source "$(dirname "$0")/publish_lib.sh"
G="$(game_dir "$1")"; PKG="$(pkg_of "$G")"; WORK="$HERE/.work/$1"; mkdir -p "$WORK"
TRACK="${2:-$(python3 -c "import sys,json;print(json.load(open('$G/store/status.json')).get('play',{}).get('track',''))" 2>/dev/null || true)}"; TRACK="${TRACK:-internal}"
CODE="$(grep -E '^version/code=' "$G/export_presets.cfg" | head -1 | cut -d= -f2)"
python3 "$HERE_PLUGIN/make_metadata.py" "$G" "$WORK/metadata" --code "$CODE"
need_key
fastlane supply --json_key "$KEY" --package_name "$PKG" --metadata_path "$WORK/metadata" --track "$TRACK" --version_code "$CODE" \
  --skip_upload_aab true --skip_upload_apk true
echo "listing refreshed (track $TRACK, version code $CODE)"
