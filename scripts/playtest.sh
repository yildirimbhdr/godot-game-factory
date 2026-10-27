#!/usr/bin/env bash
# Deterministic scripted playtest using Godot Movie Maker (fixed fps, no real-time dependence).
# usage: playtest.sh <project-dir> <scenario.json> [--seconds N] [--resolution WxH] [--notch] [--lenient-audio] [--out DIR]
# Note: macOS clamps the window to the screen height (1664 px here), so frames cannot exceed it; store screenshots use 936x1664.
# Output: <out>/log.txt, <out>/marks/<name>.png, <out>/frame*.wav; exits 1 on any failure.
set -euo pipefail

PROJECT="$(cd "$1" && pwd)"; SCENARIO="$(cd "$(dirname "$2")" && pwd)/$(basename "$2")"; shift 2
SECS=12; RES=""; NOTCH=""; OUT=""; STRICT_AUDIO=1
while [ $# -gt 0 ]; do
  case "$1" in
    --seconds) SECS="$2"; shift 2;;
    --resolution) RES="$2"; shift 2;;
    --notch) NOTCH="--notch"; shift;;
    --lenient-audio) STRICT_AUDIO=0; shift;;
    --out) OUT="$2"; shift 2;;
    *) echo "unknown option $1" >&2; exit 2;;
  esac
done
GODOT="${GODOT:-godot}"
FPS=20
OUT="${OUT:-$PROJECT/.playtest/$(basename "$SCENARIO" .json)}"
rm -rf "$OUT"; mkdir -p "$OUT/marks"

# A fresh project needs two import passes: the first loads themes/scenes before their textures are imported.
if [ ! -d "$PROJECT/.godot/imported" ]; then
  "$GODOT" --headless --path "$PROJECT" --import >/dev/null 2>&1 || true
  "$GODOT" --headless --path "$PROJECT" --import >/dev/null 2>&1 || true
fi

ARGS=(--path "$PROJECT" --always-on-top --write-movie "$OUT/frame.png" --fixed-fps "$FPS" --quit-after $((SECS * FPS)))
if [ -n "$RES" ]; then
  # --resolution alone does not resize Movie Maker frames; a temporary override.cfg does.
  trap 'rm -f "$PROJECT/override.cfg"' EXIT
  printf '[display]\nwindow/size/window_width_override=%s\nwindow/size/window_height_override=%s\n' "${RES%x*}" "${RES#*x}" > "$PROJECT/override.cfg"
fi
# macOS skips drawing while the display sleeps, which silently truncates the recording; keep it awake.
KEEP_AWAKE=(); if command -v caffeinate >/dev/null; then caffeinate -u -t 2 || true; KEEP_AWAKE=(caffeinate -d -i); fi
# macOS stops presenting frames when the window is hidden or the display idles, which truncates the recording while the game logic keeps
# running (expectations still pass, marks go stale: lessons 0008 and 0031). Compare the recorded frames with the expected count and retry.
EXPECTED=$((SECS * FPS))
for ATTEMPT in 1 2 3; do
  rm -rf "$OUT/marks"; mkdir -p "$OUT/marks"; rm -f "$OUT"/frame*.png "$OUT"/frame*.wav
  "${KEEP_AWAKE[@]}" "$GODOT" "${ARGS[@]}" -- --playtest="$SCENARIO" --shots="$OUT/marks" $NOTCH > "$OUT/log.txt" 2>&1 || true
  RECORDED="$(grep -oE '[0-9]+ frames at' "$OUT/log.txt" | grep -oE '^[0-9]+' || echo 0)"
  [ "${RECORDED:-0}" -ge $((EXPECTED * 98 / 100)) ] && break
  echo "recording truncated ($RECORDED of $EXPECTED frames), attempt $ATTEMPT" >&2
  sleep 3
done
if [ "${RECORDED:-0}" -lt $((EXPECTED * 98 / 100)) ]; then
  echo "PLAYTEST UNRELIABLE: recording stopped at $RECORDED of $EXPECTED frames three times; marks would be stale. Keep the Godot window visible and the Mac awake, then rerun." ; exit 1
fi

# keep only the frames the scenario marked
grep -E '^\[playtest\] mark ' "$OUT/log.txt" | while read -r _ _ name frame; do
  n="${frame#frame=}"
  src="$OUT/frame$(printf '%08d' "$n").png"
  [ -f "$OUT/marks/$name.png" ] || { [ -f "$src" ] && cp "$src" "$OUT/marks/$name.png"; }
done
find "$OUT" -maxdepth 1 -name 'frame*.png' -delete

# Movie Maker keeps audio playbacks alive a moment longer at shutdown, so Godot prints "resources still in use at exit".
# A normal run does not (verified), so that single engine line is ignored here; every other error still fails.
FAILURES="$(grep -E '\[playtest\]\[FAIL\]|SCRIPT ERROR|Parse Error|^ERROR:' "$OUT/log.txt" | grep -v -E 'resources still in use at exit|Texture with GL ID of [0-9]+: leaked|RID allocations of type .* were leaked at exit' | sort -u || true)"
if [ -n "$FAILURES" ]; then
  echo "PLAYTEST FAILED"; echo "$FAILURES"; exit 1
fi
# audio (strict unless --lenient-audio): the recording must contain sound without clipping, and no SFX may be missing.
# Music is optional and never counted as missing.
WAV="$(ls "$OUT"/*.wav 2>/dev/null | head -1 || true)"
if [ -n "$WAV" ] && command -v python3 >/dev/null; then
  if AUDIO="$(python3 "$(dirname "$0")/check_audio.py" "$WAV")"; then echo "audio: $AUDIO"; else echo "audio: SILENT or CLIPPING ($AUDIO)"; [ "$STRICT_AUDIO" = 1 ] && exit 1; fi
fi
MISSING="$(grep -E '^\[audio\] missing sound' "$OUT/log.txt" | sort -u || true)"
if [ -n "$MISSING" ]; then echo "audio: missing sounds"; echo "$MISSING"; [ "$STRICT_AUDIO" = 1 ] && exit 1; fi
# record a Definition-of-Done stamp (strict audio only) so scripts/dod_check.py can see which shapes were verified
if [ "$STRICT_AUDIO" = 1 ]; then
  python3 - "$PROJECT/.playtest/dod_stamp.json" "$(basename "$SCENARIO" .json)@${RES:-default}${NOTCH:+-notch}" <<'PY'
import json, sys, time
from pathlib import Path
p = Path(sys.argv[1]); p.parent.mkdir(parents=True, exist_ok=True)
d = json.loads(p.read_text()) if p.is_file() else {"runs": {}}
d["runs"][sys.argv[2]] = time.time()
p.write_text(json.dumps(d, indent=1))
PY
fi
echo "PLAYTEST OK  marks: $(ls "$OUT/marks" | tr '\n' ' ')"
