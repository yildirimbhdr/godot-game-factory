#!/usr/bin/env bash
# Publish every game's privacy/support pages to ONE Firebase Hosting site that belongs to the user.
# usage: site_deploy.sh [--dry-run]
# Reads the profile (gf_profile.py): workspace, firebase_project, hosting_site. It copies */store/out/site/<slug> into
# <workspace>/_site/public/<slug>, writes <workspace>/_site/firebase.json, then deploys ONLY that site (never the default
# site of a project, which belongs to an app). Create the site once: firebase hosting:sites:create <hosting_site> --project <project>
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
get() { python3 -c "import sys; sys.path.insert(0,'$HERE'); import gf_profile; print(gf_profile.load()['$1'])"; }
WS="$(get workspace)"; PROJECT="$(get firebase_project)"; SITE="$(get hosting_site)"
[ -n "$WS" ] && [ -n "$PROJECT" ] && [ -n "$SITE" ] || { echo "profile needs workspace, firebase_project and hosting_site" >&2; exit 1; }
[ "$SITE" != "$PROJECT" ] || { echo "refusing to deploy over the project's default site ($SITE)" >&2; exit 1; }
DEST="$WS/_site"; rm -rf "$DEST/public"; mkdir -p "$DEST/public"
for d in "$WS"/*/store/out/site/*/; do [ -d "$d" ] && cp -R "$d" "$DEST/public/$(basename "$d")"; done
[ -d "$DEST/static" ] && cp -R "$DEST/static/." "$DEST/public/"   # root files such as app-ads.txt
printf '<!doctype html><meta charset="utf-8"><title>%s</title>' "$SITE" > "$DEST/public/index.html"
cat > "$DEST/firebase.json" <<JSON
{ "hosting": { "site": "$SITE", "public": "public", "cleanUrls": true, "ignore": ["firebase.json", "**/.*"] } }
JSON
echo "pages:"; (cd "$DEST/public" && find . -name index.html | sort)
[ "${1:-}" = "--dry-run" ] && exit 0
(cd "$DEST" && firebase deploy --only "hosting:$SITE" --project "$PROJECT" --non-interactive)
