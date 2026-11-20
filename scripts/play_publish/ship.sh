#!/usr/bin/env bash
# One command from a finished game to a Play draft: checks, build, upload, bookkeeping, and the list of steps that stay with you.
# usage: scripts/play_publish/ship.sh <game-folder> [--track internal|closed|production] [--notes-en TXT --notes-tr TXT] [--version X.Y.Z] [--dry]
#
#  1. preflight   definition of done (release, Android), package names, listing, graphics, live privacy/support pages, app-ads.txt, keys
#  2. new or update   (build, AAB check, upload) decided from store/status.json: nothing on Play yet -> publish_new.sh (site + listing + first AAB);
#                     something on Play -> publish_update.sh (version bump + AAB + release notes)
#  3. the built AAB is checked too (real AdMob app id inside its manifest, package name) before anything is uploaded
#  4. the upload is recorded in store/status.json (gf_status.py), the manual to-do list is refreshed and printed
# --dry does everything except the upload (and restores export_presets.cfg).
# Not covered by the Play API, so listed at the end and yours: privacy URL field, Data safety, content rating, ads declaration,
# target audience, testers, "Send for review". store/declarations.html has the answers.
set -euo pipefail
source "$(dirname "$0")/publish_lib.sh"
GAME="${1:?usage: ship.sh <game-folder> [--track T] [--notes-en TXT --notes-tr TXT] [--version V] [--dry]}"; shift
TRACK=""; EN=""; TR=""; VER=""; DRY=""
while [ $# -gt 0 ]; do
  case "$1" in
    --track) TRACK="$2"; shift 2;;
    --notes-en) EN="$2"; shift 2;;
    --notes-tr) TR="$2"; shift 2;;
    --version) VER="$2"; shift 2;;
    --dry) DRY="--dry"; shift;;
    *) echo "unknown option $1" >&2; exit 2;;
  esac
done
G="$(game_dir "$GAME")"
st() { python3 -c "import sys;sys.path.insert(0,'$PLUGIN_SCRIPTS');import gf_status;d=gf_status.load(__import__('pathlib').Path('$G'));print(d['play']['$1'])"; }

echo "== 1/3 preflight ($GAME)"
python3 "$HERE_PLUGIN/preflight.py" "$G" || { echo; echo "Fix the FAIL lines above, then run ship.sh again."; exit 1; }

STATE="$(st state)"
if [ "$STATE" = "none" ]; then
  echo; echo "== 2/3 first release: site + listing + first AAB (track ${TRACK:-internal})"
  [ -z "$DRY" ] && echo "This publishes the privacy and support pages (public) and uploads a DRAFT to Google Play."
  bash "$HERE_PLUGIN/publish_new.sh" "$GAME" "${TRACK:-internal}" $DRY
else
  LAST_TRACK="$(st track)"; TRACK="${TRACK:-${LAST_TRACK:-production}}"
  if [ -z "$EN" ] || [ -z "$TR" ]; then   # default release notes: the listing's "whats_new"
    EN="${EN:-$(python3 -c "import json;print(json.load(open('$G/store/listing.json'))['en'].get('whats_new',''))")}"
    TR="${TR:-$(python3 -c "import json;print(json.load(open('$G/store/listing.json'))['tr'].get('whats_new',''))")}"
  fi
  [ -n "$EN" ] && [ -n "$TR" ] || { echo "update needs release notes: pass --notes-en and --notes-tr (or fill whats_new in store/listing.json)"; exit 1; }
  echo; echo "== 2/3 update (Play has $STATE $(st version), track $TRACK)"
  bash "$HERE_PLUGIN/publish_update.sh" "$GAME" "$EN" "$TR" "$VER" "$TRACK" $DRY
fi

echo; echo "== 3/3 what is left for you"
if [ -n "$DRY" ]; then
  echo "(dry run: nothing was uploaded or recorded)"
else
  python3 "$PLUGIN_SCRIPTS/store_declarations.py" "$G" >/dev/null
  python3 "$PLUGIN_SCRIPTS/gf_status.py" init "$G" >/dev/null
fi
python3 "$PLUGIN_SCRIPTS/gf_status.py" todo "$G"
echo
echo "Answers for the forms (copy buttons, tick boxes): open $G/store/declarations.html"
echo "Tick a step when you did it:  python3 $PLUGIN_SCRIPTS/gf_status.py done $G <id>"
