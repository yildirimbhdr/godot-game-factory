#!/usr/bin/env python3
"""Create a game project from templates/godot-base in one deterministic step.

  new_game.py <slug> "<Game Title>" [--dest DIR] [--bundle-id com.you.slug]

Copies the template (never edits it), sets the game name and boot-splash colour, imports the project twice (a fresh
project needs two passes) and runs the Definition-of-Done check so the open items are visible from minute one.
Theme, sounds and art come next (see skills/godot-scaffold). Refuses to overwrite an existing folder.
"""
import argparse, re, shutil, subprocess, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SKIP = shutil.ignore_patterns(".godot", ".playtest", "override.cfg", ".DS_Store")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("slug")
    ap.add_argument("title")
    ap.add_argument("--dest", default=".")
    ap.add_argument("--bundle-id", default="")
    a = ap.parse_args()
    if not re.fullmatch(r"[a-z0-9][a-z0-9_-]*", a.slug):
        sys.exit("slug must be lowercase letters, digits, - or _")
    game = Path(a.dest).resolve() / a.slug
    if game.exists():
        sys.exit(f"{game} already exists; refusing to overwrite")
    shutil.copytree(ROOT / "templates" / "godot-base", game, ignore=SKIP)
    pg = game / "project.godot"
    t = pg.read_text()
    t = re.sub(r'^config/name=".*"$', f'config/name="{a.title}"', t, flags=re.M)
    pg.write_text(t)
    (game / "GDD.md").write_text(f"# {a.title}\n\nIdea and core loop:\n\nStructure (levels with a level map | endless with a high score):\n\n"
                                 "What we will NOT build:\n\nPacing (no-input / greedy-bot time to first death):\n")
    if a.bundle_id:
        (game / "bundle_id.txt").write_text(a.bundle_id + "\n")
    for _ in range(2):
        subprocess.run(["godot", "--headless", "--path", str(game), "--import"], capture_output=True)
    print(f"created {game}\nopen items right now (expected: theme, icon, assets, playtests, DOD.md):")
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    import dod_check
    print("\n".join("  - " + p for p in dod_check.check(game)))
    print("\nnext: theme (build_theme.py), sfx.sh build, then build the game in game/ and run scripts/play.sh")
    return 0


if __name__ == "__main__":
    sys.exit(main())
