#!/usr/bin/env bash
# Build a signed App Store archive of a Godot iOS game and (optionally) upload it to App Store Connect.
# usage: ios_release.sh <project-dir> <work-dir> [--upload] [preset-name]     (default preset: "iOS")
# Needs: Xcode signed in with the team's Apple ID (automatic signing), the bundle id registered as an explicit App ID and an
# App Store Connect app record for it (the upload fails without the record). The team id is read from the preset.
# Why the odd flags: Godot's release export writes a MANUAL "Apple Distribution" identity into the Xcode project, which conflicts
# with automatic signing ("conflicting provisioning settings"). The archive is therefore made with the Apple Development identity
# and automatic style, and the distribution signing happens in -exportArchive (method app-store-connect, automatic).
set -euo pipefail
PROJECT="$(cd "$1" && pwd)"; WORK="$2"; shift 2
UPLOAD=0; PRESET="iOS"
for a in "$@"; do case "$a" in --upload) UPLOAD=1;; *) PRESET="$a";; esac; done
GODOT="${GODOT:-godot}"
TEAM="$(sed -n 's/^application\/app_store_team_id="\(.*\)"/\1/p' "$PROJECT/export_presets.cfg" | head -1)"
[ -n "$TEAM" ] || { echo "no application/app_store_team_id in export_presets.cfg" >&2; exit 1; }
mkdir -p "$WORK"; WORK="$(cd "$WORK" && pwd)"
rm -rf "$WORK/proj" "$WORK/App.xcarchive" "$WORK/exported"; mkdir -p "$WORK/proj"
"$GODOT" --headless --path "$PROJECT" --export-release "$PRESET" "$WORK/proj/App.xcodeproj" > "$WORK/export.log" 2>&1 \
  || { echo "godot export failed, see $WORK/export.log" >&2; exit 1; }
( cd "$WORK/proj" && xcodebuild -project App.xcodeproj -scheme App -configuration Release -destination 'generic/platform=iOS' \
    -archivePath "$WORK/App.xcarchive" -allowProvisioningUpdates DEVELOPMENT_TEAM="$TEAM" \
    CODE_SIGN_IDENTITY="Apple Development" CODE_SIGN_STYLE=Automatic archive > "$WORK/archive.log" 2>&1 ) \
  || { echo "archive failed, see $WORK/archive.log" >&2; grep "error:" "$WORK/archive.log" | head -3 >&2; exit 1; }
DEST=export; [ "$UPLOAD" = 1 ] && DEST=upload
cat > "$WORK/ExportOptions.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>method</key><string>app-store-connect</string>
<key>teamID</key><string>$TEAM</string>
<key>signingStyle</key><string>automatic</string>
<key>destination</key><string>$DEST</string>
<key>uploadSymbols</key><true/>
</dict></plist>
PLIST
xcodebuild -exportArchive -archivePath "$WORK/App.xcarchive" -exportPath "$WORK/exported" -exportOptionsPlist "$WORK/ExportOptions.plist" \
  -allowProvisioningUpdates > "$WORK/upload.log" 2>&1 || { echo "exportArchive failed, see $WORK/upload.log" >&2; exit 1; }
grep -E "Uploaded|EXPORT SUCCEEDED" "$WORK/upload.log" | sed 's/^/  /'
echo "done ($DEST). dSYM 'Upload Symbols Failed' warnings for third-party frameworks are harmless."
