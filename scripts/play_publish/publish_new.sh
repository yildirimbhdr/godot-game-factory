#!/usr/bin/env bash
# First Play release of a game: privacy/support site -> Firebase, store listing + images -> Play, signed AAB -> Play (draft).
# usage: scripts/play_publish/publish_new.sh <game-folder> [track=internal] [--dry]
# The very first AAB of a brand-new app record may still have to be uploaded by hand once (Play API limit); after that this works.
set -euo pipefail
source "$(dirname "$0")/publish_lib.sh"
G="$(game_dir "$1")"; TRACK="${2:-internal}"; DRY="${3:-}"
PKG="$(pkg_of "$G")"; WORK="$HERE/.work/$1"; mkdir -p "$WORK"
CODE="$(grep -E '^version/code=' "$G/export_presets.cfg" | head -1 | cut -d= -f2)"
echo "== $1 ($PKG) version code $CODE, track $TRACK"
# 1 privacy + support pages
SLUG="$(ls "$G/store/out/site" | head -1)"
if [ -n "$SLUG" ]; then
  rm -rf "$GAMES/_site/public/$SLUG"; cp -R "$G/store/out/site/$SLUG" "$GAMES/_site/public/"
  [ "$DRY" = "--dry" ] || (cd "$GAMES/_site" && firebase deploy --only hosting 2>&1 | tail -3)
  echo "privacy: https://appstudioz-games.web.app/$SLUG/privacy"
fi
# 2 metadata + images
python3 "$HERE_PLUGIN/make_metadata.py" "$G" "$WORK/metadata" --code "$CODE"
# 3 AAB
AAB="$GAMES/_builds/$1-$(grep -E '^version/name=' "$G/export_presets.cfg" | head -1 | cut -d'"' -f2)-$CODE.aab"
mkdir -p "$GAMES/_builds"
[ -f "$AAB" ] || bash "$PLUGIN_SCRIPTS/android_release.sh" "$G" "$AAB"
echo "aab: $AAB"
[ "$DRY" = "--dry" ] && { echo "dry run: nothing uploaded"; exit 0; }
need_key
fastlane supply --json_key "$KEY" --package_name "$PKG" --aab "$AAB" --track "$TRACK" --release_status draft \
  --metadata_path "$WORK/metadata" --skip_upload_changelogs false
echo "uploaded as a DRAFT on '$TRACK'. Review + 'Send for review' in Play Console stays with you."
