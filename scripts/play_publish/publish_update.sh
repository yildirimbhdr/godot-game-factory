#!/usr/bin/env bash
# Ship an update: bumps version code + name, builds the signed AAB, uploads it with release notes (EN+TR) to Play as a draft.
# usage: scripts/play_publish/publish_update.sh <game-folder> "<EN notes>" "<TR notes>" [version-name] [track=production] [--dry]
# Without version-name only the patch number goes up (1.1.0 -> 1.1.1). Store texts/images are NOT touched; use publish_listing.sh for that.
set -euo pipefail
source "$(dirname "$0")/publish_lib.sh"
G="$(game_dir "$1")"; EN="$2"; TR="$3"; NAME="${4:-}"; TRACK="${5:-production}"; DRY="${6:-}"
PKG="$(pkg_of "$G")"; P="$G/export_presets.cfg"; WORK="$HERE/.work/$1"; mkdir -p "$WORK"
CODE=$(( $(grep -E '^version/code=' "$P" | head -1 | cut -d= -f2) + 1 ))
OLD="$(grep -E '^version/name=' "$P" | head -1 | cut -d'"' -f2)"
if [ -z "$NAME" ]; then NAME="${OLD%.*}.$(( ${OLD##*.} + 1 ))"; fi
IOSB=$(( $(grep -E '^application/version=' "$P" | head -1 | cut -d'"' -f2) + 1 ))
sed -i '' -E "s/^version\/code=.*/version\/code=$CODE/; s/^version\/name=.*/version\/name=\"$NAME\"/; s/^application\/short_version=.*/application\/short_version=\"$NAME\"/; s/^application\/version=.*/application\/version=\"$IOSB\"/" "$P"
echo "== $1 $OLD -> $NAME (code $CODE, ios build $IOSB), track $TRACK"
AAB="$GAMES/_builds/$1-$NAME-$CODE.aab"; mkdir -p "$GAMES/_builds"
bash "$PLUGIN_SCRIPTS/android_release.sh" "$G" "$AAB"
python3 "$HERE_PLUGIN/make_metadata.py" "$G" "$WORK/metadata" --no-listing --code "$CODE" --notes-en "$EN" --notes-tr "$TR"
[ "$DRY" = "--dry" ] && { echo "dry run: AAB built at $AAB, nothing uploaded"; exit 0; }
need_key
fastlane supply --json_key "$KEY" --package_name "$PKG" --aab "$AAB" --track "$TRACK" --release_status draft \
  --metadata_path "$WORK/metadata" --skip_upload_metadata --skip_upload_images --skip_upload_screenshots
echo "uploaded $NAME ($CODE) as a DRAFT on '$TRACK'. Press 'Send for review' in Play Console."
