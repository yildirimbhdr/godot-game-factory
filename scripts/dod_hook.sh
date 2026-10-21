#!/usr/bin/env bash
# Stop hook: do not let Claude call a Godot game "done" while the Definition of Done is not met.
# Active only while a game project is being edited (a source file changed in the last 2 hours).
# Exit 2 sends the failures back to Claude so it keeps working; exit 0 lets it stop.
HERE="$(cd "$(dirname "$0")" && pwd)"
INPUT="$(cat)"
exec python3 - "$HERE" "$INPUT" <<'PY'
import json, subprocess, sys, time
from pathlib import Path
here, raw = Path(sys.argv[1]), sys.argv[2]
try:
    data = json.loads(raw or "{}")
except ValueError:
    data = {}
if data.get("stop_hook_active"):          # already continued once because of this hook: never loop
    sys.exit(0)
sys.path.insert(0, str(here))
import dod_check
cwd = Path(data.get("cwd") or ".").resolve()
candidates = [p for p in [cwd, *cwd.parents] if (p / "project.godot").is_file()][:1]
if not candidates:
    candidates = [d for d in cwd.iterdir() if d.is_dir() and (d / "project.godot").is_file()] if cwd.is_dir() else []
active = [(dod_check.newest_source(p), p) for p in candidates]
active = [(t, p) for t, p in active if time.time() - t < 2 * 3600]
if not active:
    sys.exit(0)
newest, project = max(active)
problems = dod_check.check(project)
if not problems:
    sys.exit(0)
sys.stderr.write(f"Definition of Done is not met for {project.name}. Fix these before saying the game is done "
                 "(skills/playtest-verify, then update DOD.md):\n- " + "\n- ".join(problems) + "\n")
sys.exit(2)
PY
