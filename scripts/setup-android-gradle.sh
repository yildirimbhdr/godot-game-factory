#!/usr/bin/env bash
# Prepare a Godot project for a Gradle-based Android export (needed by AdMob and Firebase plugins).
# usage: setup-android-gradle.sh <project-dir> [--firebase]
# Does: installs Godot's Android build template (same as the editor's "Install Android Build Template"),
# adds android/build/.gdignore, and with --firebase patches build.gradle for the google-services plugin.
# Idempotent. Does not touch editor settings (a Gradle-compatible JDK, 17 or 21, must be set there: see skills/doctor).
set -euo pipefail
PROJECT="$(cd "$1" && pwd)"; FIREBASE=0; [ "${2:-}" = "--firebase" ] && FIREBASE=1
GODOT="${GODOT:-godot}"
VER="$("$GODOT" --version | sed -E 's/^([0-9]+\.[0-9]+(\.[0-9]+)?\.[a-z0-9]+).*/\1/')"
TPL="$HOME/Library/Application Support/Godot/export_templates/$VER/android_source.zip"
[ -f "$TPL" ] || { echo "missing $TPL (install export templates for $VER)" >&2; exit 1; }
# -n: restore any template file that is missing (e.g. a fresh clone) but never overwrite a patched build.gradle
mkdir -p "$PROJECT/android/build"
unzip -q -n "$TPL" -d "$PROJECT/android/build"
echo "$VER" > "$PROJECT/android/.build_version"
# Without this Godot imports the template's own files and Gradle then fails on the stray .import files.
touch "$PROJECT/android/build/.gdignore"
find "$PROJECT/android/build" \( -name '*.import' -o -name '*.uid' \) -delete
if [ "$FIREBASE" = 1 ] && ! grep -q 'google-services' "$PROJECT/android/build/build.gradle"; then
  tmp="$(mktemp)"
  {
    printf '%s\n' "// Firebase: the buildscript block must stay the very first block of this file." \
      "buildscript {" "    repositories {" "        google()" "        mavenCentral()" "    }" \
      "    dependencies {" "        classpath 'com.google.gms:google-services:4.4.4'" "    }" "}" ""
    cat "$PROJECT/android/build/build.gradle"
    printf '\n%s\n' "apply plugin: 'com.google.gms.google-services'"
  } > "$tmp"
  mv "$tmp" "$PROJECT/android/build/build.gradle"
fi
echo "Android Gradle template ready in $PROJECT/android/build (Godot $VER)"
