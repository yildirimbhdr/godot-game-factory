#!/usr/bin/env bash
# One-time machine setup for store uploads with fastlane (no Claude tokens afterwards). Idempotent, prints what is still missing.
# usage: fastlane_setup.sh
# Secrets stay in ~/.game-factory/keys (chmod 700) and ~/.game-factory/fastlane.env; never in a repo.
set -uo pipefail
KEYS="$HOME/.game-factory/keys"; ENVF="$HOME/.game-factory/fastlane.env"
mkdir -p "$KEYS" && chmod 700 "$KEYS"
ok() { echo "  OK   $1"; }; miss() { echo "  TODO $1"; MISSING=1; }
MISSING=0
echo "fastlane setup check"
command -v fastlane >/dev/null && ok "fastlane $(fastlane --version 2>/dev/null | tail -1)" || miss "install: brew install fastlane"
[ -f "$ENVF" ] || cat > "$ENVF" <<'ENV'
# Used by scripts/fl.sh. Fill in once. Paths only; the key files themselves live in ~/.game-factory/keys
export GF_ASC_KEY_ID=""        # 10 characters, App Store Connect > Users and Access > Integrations > Team Keys
export GF_ASC_ISSUER_ID=""     # UUID shown at the top of the same page
export GF_ASC_KEY_PATH="$HOME/.game-factory/keys/AuthKey.p8"
export GF_PLAY_JSON_KEY="$HOME/.game-factory/keys/play-service-account.json"
export FASTLANE_SKIP_UPDATE_CHECK=1
export FASTLANE_OPT_OUT_USAGE=1
ENV
chmod 600 "$ENVF"
# shellcheck disable=SC1090
source "$ENVF"
[ -n "${GF_ASC_KEY_ID:-}" ] && [ -n "${GF_ASC_ISSUER_ID:-}" ] && ok "ASC key id and issuer id set" || miss "fill GF_ASC_KEY_ID and GF_ASC_ISSUER_ID in $ENVF"
[ -f "${GF_ASC_KEY_PATH:-/nonexistent}" ] && ok "ASC private key at $GF_ASC_KEY_PATH" || miss "save the downloaded AuthKey_XXXX.p8 as $KEYS/AuthKey.p8 (chmod 600)"
[ -f "${GF_PLAY_JSON_KEY:-/nonexistent}" ] && ok "Play service account key" || miss "save the Play service account JSON as $KEYS/play-service-account.json (chmod 600)"
HERE="$(cd "$(dirname "$0")" && pwd)"
KS="${GF_KEYSTORE:-$(python3 "$HERE/gf_profile.py" get android_keystore)}"; KS="${KS:-$HOME/.game-factory/keystores/upload.keystore}"
[ -f "$KS" ] && ok "Android upload keystore ($KS)" || miss "Android upload keystore missing: create one (skills/store-release, Builds) and set it with gf_profile.py set android_keystore <path>"
if [ "$MISSING" = 1 ]; then echo; echo "Steps for the missing keys: skills/store-release/playbooks/fastlane.md (section One-time setup)"; exit 1; fi
echo "all set"
