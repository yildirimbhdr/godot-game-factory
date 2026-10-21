#!/usr/bin/env bash
# Build a signed release AAB for Google Play.
# usage: android_release.sh <project-dir> <output.aab> [preset-name]   (default preset: "Android Release")
# The upload keystore and its password never live in the repo: the keystore is ~/.game-factory/keystores/<name>.keystore
# (override with GF_KEYSTORE) and the password is read from the macOS Keychain (service game-factory-android-upload).
# The preset must be a Gradle build with gradle_build/export_format=1 (AAB) and package/signed=true.
set -euo pipefail
PROJECT="$(cd "$1" && pwd)"; OUT="$2"; PRESET="${3:-Android Release}"
KS="${GF_KEYSTORE:-$HOME/.game-factory/keystores/appstudioz-upload.keystore}"
[ -f "$KS" ] || { echo "no keystore at $KS" >&2; exit 1; }
PW="$(security find-generic-password -a "$USER" -s game-factory-android-upload -w)"
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$KS"
export GODOT_ANDROID_KEYSTORE_RELEASE_USER="${GF_KEY_ALIAS:-upload}"
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="$PW"
GODOT="${GODOT:-godot}"
mkdir -p "$(dirname "$OUT")"
"$GODOT" --headless --path "$PROJECT" --export-release "$PRESET" "$OUT"
echo "built $OUT ($(du -h "$OUT" | cut -f1))"
