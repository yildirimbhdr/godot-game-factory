#!/usr/bin/env bash
# One command from a finished game to the App Store Connect version page: checks, build upload, texts and screenshots, bookkeeping.
# usage: scripts/apple_publish/ship_ios.sh <game-folder> [--dry] [--submit] [--no-build]
#
#  1. preflight --platform ios   definition of done (iOS ids), bundle id, team id, build number, plist, screenshots, API key, tools, signing identity
#  2. fastlane_prepare.py        regenerates <game>/fastlane (metadata + screenshots from store/listing.json and store/out), first=1.0 without "What's New"
#  3. fastlane ios status        read-only: the app record must exist (created once by hand: New App); prints Apple's versions and builds
#  4. ios_release.sh --upload    signed archive -> App Store Connect; then `fastlane ios wait_build` until Apple finished processing it
#  5. fastlane ios metadata      texts and screenshots (never submits); the upload is recorded in store/status.json
# --dry: steps 1 and 3 only (3 needs the API key), nothing is built or uploaded.
# --submit: after 5, attach the build and send for review (`fastlane ios submit`). Only when YOU mean it: App Privacy, age rating and
#           review contact must already be filled in App Store Connect (store/declarations.html lists the answers). Without --submit
#           "Add for Review" stays your click.
# --no-build: skip step 4 (the build is already uploaded).
set -euo pipefail
HERE_APPLE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE_APPLE/../play_publish/publish_lib.sh"
GAME="${1:?usage: ship_ios.sh <game-folder> [--dry] [--submit] [--no-build]}"; shift
DRY=""; SUBMIT=""; NOBUILD=""
for a in "$@"; do case "$a" in --dry) DRY=1;; --submit) SUBMIT=1;; --no-build) NOBUILD=1;; *) echo "unknown option $a" >&2; exit 2;; esac; done
G="$(game_dir "$GAME")"
[ -f "$HOME/.game-factory/fastlane.env" ] && source "$HOME/.game-factory/fastlane.env"
st() { python3 -c "import sys;sys.path.insert(0,'$PLUGIN_SCRIPTS');import gf_status,pathlib;d=gf_status.load(pathlib.Path('$G'));print(d['apple']['$1'])"; }
preset() { sed -n "s#^$1=\"\(.*\)\"#\1#p" "$G/export_presets.cfg" | head -1; }   # first match = the iOS preset
VER="$(preset application/short_version)"; BUILD="$(preset application/version)"

echo "== 1/5 preflight (ios) $GAME"
python3 "$HERE_PLUGIN/preflight.py" "$G" --platform ios ${NOBUILD:+--reuse-build} || { echo; echo "Fix the FAIL lines above, then run again."; exit 1; }

echo; echo "== 2/5 fastlane project"
FIRST=""; [ "$(st state)" = "none" ] && FIRST="--first"
python3 "$PLUGIN_SCRIPTS/fastlane_prepare.py" "$G" $FIRST | tail -3

echo; echo "== 3/5 App Store Connect (read-only)"
STATUS_OUT="$(bash "$PLUGIN_SCRIPTS/fl.sh" "$G" ios status 2>&1)" || { echo "$STATUS_OUT" | tail -8; echo; echo "status failed: fix the message above (an app record is created once with New App in App Store Connect, same bundle id)."; exit 1; }
echo "$STATUS_OUT" | grep "GF_ASC" | sed 's/^.*GF_ASC/  GF_ASC/' || true

if [ -n "$DRY" ]; then echo; echo "dry run: stopped before building. Would upload $VER ($BUILD)."; python3 "$PLUGIN_SCRIPTS/gf_status.py" todo "$G"; exit 0; fi

if [ -z "$NOBUILD" ]; then
  echo; echo "== 4/5 build $VER ($BUILD) -> App Store Connect"
  mkdir -p "$GAMES/_builds"
  bash "$PLUGIN_SCRIPTS/ios_release.sh" "$G" "$GAMES/_builds/ios-$GAME-$VER-$BUILD" --upload
  bash "$PLUGIN_SCRIPTS/fl.sh" "$G" ios wait_build build:"$BUILD"
fi

echo; echo "== 5/5 texts and screenshots"
bash "$PLUGIN_SCRIPTS/fl.sh" "$G" ios metadata version:"$VER"
python3 "$PLUGIN_SCRIPTS/release.py" store "$G" apple uploaded --version "$VER" --build "$BUILD" >/dev/null
echo "recorded: apple uploaded $VER ($BUILD) in store/status.json"

if [ -n "$SUBMIT" ]; then
  echo; echo "== submit for review"
  bash "$PLUGIN_SCRIPTS/fl.sh" "$G" ios submit build:"$BUILD" version:"$VER"
  python3 "$PLUGIN_SCRIPTS/release.py" store "$G" apple in_review --version "$VER" --build "$BUILD" >/dev/null
  echo "recorded: apple in_review"
fi

python3 "$PLUGIN_SCRIPTS/store_declarations.py" "$G" >/dev/null
python3 "$PLUGIN_SCRIPTS/gf_status.py" init "$G" >/dev/null
echo; echo "== left for you"
python3 "$PLUGIN_SCRIPTS/gf_status.py" todo "$G"
echo; echo "Answers for the forms: $G/store/declarations.html"
