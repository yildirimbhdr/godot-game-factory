#!/usr/bin/env bash
# Build a signed release AAB for Google Play.
# usage: android_release.sh <project-dir> <output.aab> [preset-name]   (default preset: "Android Release")
# The upload keystore and its password never live in the repo. Keystore path: GF_KEYSTORE, else the profile's android_keystore
# (scripts/gf_profile.py), else ~/.game-factory/keystores/upload.keystore. Password: macOS Keychain, service from the profile
# (android_keychain_service, default game-factory-android-upload).
# The preset must be a Gradle build with gradle_build/export_format=1 (AAB) and package/signed=true.
set -euo pipefail
PROJECT="$(cd "$1" && pwd)"; OUT="$2"; PRESET="${3:-Android Release}"
HERE="$(cd "$(dirname "$0")" && pwd)"
KS="${GF_KEYSTORE:-$(python3 "$HERE/gf_profile.py" get android_keystore)}"
KS="${KS:-$HOME/.game-factory/keystores/upload.keystore}"
SERVICE="$(python3 "$HERE/gf_profile.py" get android_keychain_service)"; SERVICE="${SERVICE:-game-factory-android-upload}"
[ -f "$KS" ] || { echo "no keystore at $KS" >&2; exit 1; }
PW="$(security find-generic-password -a "$USER" -s "$SERVICE" -w)"
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$KS"
export GODOT_ANDROID_KEYSTORE_RELEASE_USER="${GF_KEY_ALIAS:-upload}"
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="$PW"
GODOT="${GODOT:-godot}"
mkdir -p "$(dirname "$OUT")"
"$GODOT" --headless --path "$PROJECT" --export-release "$PRESET" "$OUT"
echo "built $OUT ($(du -h "$OUT" | cut -f1))"
