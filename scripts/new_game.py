#!/usr/bin/env python3
"""Create a game project from templates/godot-base in one deterministic step.

  new_game.py --brief brief.json [--dest DIR]          (the /new-game route: the user already approved the brief)
  new_game.py <slug> "<Game Title>" [--dest DIR] [--bundle-id com.you.slug]   (bare project, no brief files)

Copies the template (never edits it), sets the game name, imports the project twice (a fresh project needs two
passes) and runs the Definition-of-Done check so the open items are visible from minute one.
With --brief it also writes GDD.md, ART_BRIEF.md, PLAN.md (phase checklist, where we stopped), brief.json,
store/status.json and a store/listing.json skeleton. It refuses a brief whose "approved" is not true, so no project
exists before the user said yes. Refuses to overwrite an existing folder.

brief.json keys (all optional except slug, title, approved):
  slug, title, approved(true), approved_on(YYYY-MM-DD), bundle_id, idea, core_loop, structure("levels"|"endless"),
  wont_build[], pacing, orientation, locales[], monetization{ads,analytics,iap}, art{style,source,mood,perspective,palette[]},
  audio{music}, stores{google_play,app_store}, notes
"""
import argparse, datetime, json, re, shutil, subprocess, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SKIP = shutil.ignore_patterns(".godot", ".playtest", "override.cfg", ".DS_Store")
sys.path.insert(0, str(Path(__file__).resolve().parent))

PHASES = [
    (1, "Idea and brief approved by the user", True),
    (2, "Project created from the template (new_game.py)", True),
    (3, "Art direction: one anchor asset approved, then the full asset set (ART_BRIEF.md, ASSETS.md)", False),
    (4, "Core loop built as Godot scenes and shown running (screenshot looked at)", False),
    (5, "Theme, UI, sound effects (and music if wanted)", False),
    (6, "Content: levels or endless rules, difficulty and pacing measured", False),
    (7, "Monetization modules, only if the brief says yes (monetization skill)", False),
    (8, "Definition of Done passes (dod_check.py, DOD.md ticked, device test)", False),
    (9, "Store package: icons, screenshots, listing texts, privacy page (store-release skill)", False),
    (10, "Builds uploaded, console forms done by the user, submitted", False),
]


def slugify(s: str) -> str:
    return re.sub(r"[^a-z0-9]", "", s.lower())


def default_bundle(slug: str) -> str:
    try:
        import gf_profile
        brand = slugify(gf_profile.load().get("brand", "") or gf_profile.load().get("developer_name", ""))
    except Exception:
        brand = ""
    return f"com.{brand or 'games'}.{slugify(slug)}"


def bullet(items) -> str:
    return "\n".join(f"- {i}" for i in items) if items else "- (nothing listed)"


def write_brief_files(game: Path, b: dict) -> None:
    title, slug = b["title"], b["slug"]
    day = b.get("approved_on") or datetime.date.today().isoformat()
    mon = b.get("monetization") or {}
    art = b.get("art") or {}
    stores = b.get("stores") or {}
    yn = lambda v: "yes" if v else "no"
    (game / "GDD.md").write_text(f"""# {title}

## Idea and core loop
{b.get('idea', '')}

{b.get('core_loop', '')}

## Structure
{'Level-based with a level map (mandatory), saved progress and stars.' if b.get('structure') == 'levels' else 'Endless with a saved high score on the menu and result screen.'}

## What we will NOT build
{bullet(b.get('wont_build'))}

## Pacing (no-input / greedy-bot time to first death)
{b.get('pacing') or 'To be measured in Godot before tuning (lesson 0026).'}

## Decisions (approved {day})
- Orientation: {b.get('orientation', 'portrait')}
- Languages: {', '.join(b.get('locales') or ['en'])}
- Music: {yn((b.get('audio') or {}).get('music'))}
- AdMob ads: {yn(mon.get('ads'))}; Firebase Analytics: {yn(mon.get('analytics'))}; In-app purchases: {yn(mon.get('iap'))}
- Stores: Google Play {yn(stores.get('google_play', True))}, App Store {yn(stores.get('app_store', True))}
- Bundle id / package: {b['bundle_id']}
{('- Notes: ' + b['notes']) if b.get('notes') else ''}
""")
    (game / "ART_BRIEF.md").write_text(f"""# Art brief: {title}

## Style (one per game, decision 0007)
- Style: {art.get('style', 'to decide')}
- Source route: {art.get('source', 'to decide')}
- Perspective: {art.get('perspective', 'to decide')}
- Mood: {art.get('mood', 'to decide')}

## Palette
{bullet(art.get('palette'))}

## Anchor asset
Not generated yet. Generate ONE anchor, show it, wait for approval, only then the full set (skill art-direction).
""")
    plan = [f"# Plan: {title}", "", f"Approved: {day}", "",
            "Phases (tick a box only when it is really done; `dod_check.py --release` needs 1-8 ticked):", ""]
    plan += [f"- [{'x' if done else ' '}] {n}. {text}" for n, text, done in PHASES]
    plan += ["", "## Where we stopped", "Project just created. Next: phase 3 (art direction).", "",
             "## Log (newest first)", f"- {day}: brief approved, project created."]
    (game / "PLAN.md").write_text("\n".join(plan) + "\n")
    (game / "brief.json").write_text(json.dumps(b, ensure_ascii=False, indent=2) + "\n")
    (game / "bundle_id.txt").write_text(b["bundle_id"] + "\n")
    store = game / "store"
    store.mkdir(exist_ok=True)
    (store / "status.json").write_text(json.dumps({"bundle_id": b["bundle_id"], "privacy_url": "", "support_url": ""}, indent=2) + "\n")
    empty = {k: "" for k in ("title", "subtitle", "short", "promo", "keywords", "full", "whats_new")}
    (store / "listing.json").write_text(json.dumps({loc: dict(empty) for loc in (b.get("locales") or ["en"])}, ensure_ascii=False, indent=2) + "\n")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("slug", nargs="?")
    ap.add_argument("title", nargs="?")
    ap.add_argument("--dest", default=".")
    ap.add_argument("--bundle-id", default="")
    ap.add_argument("--brief", default="")
    a = ap.parse_args()
    brief = None
    if a.brief:
        brief = json.loads(Path(a.brief).read_text())
        if brief.get("approved") is not True:
            sys.exit("brief.json has no \"approved\": true. Show the user the summary and get a yes first; no project is created before that.")
        for k in ("slug", "title"):
            if not brief.get(k):
                sys.exit(f"brief.json is missing {k}")
        a.slug, a.title = brief["slug"], brief["title"]
        brief["bundle_id"] = brief.get("bundle_id") or default_bundle(a.slug)
    if not a.slug or not a.title:
        sys.exit(__doc__)
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
    if brief:
        write_brief_files(game, brief)
    else:
        (game / "GDD.md").write_text(f"# {a.title}\n\nIdea and core loop:\n\nStructure (levels with a level map | endless with a high score):\n\n"
                                     "What we will NOT build:\n\nPacing (no-input / greedy-bot time to first death):\n")
        if a.bundle_id:
            (game / "bundle_id.txt").write_text(a.bundle_id + "\n")
    for _ in range(2):
        subprocess.run(["godot", "--headless", "--path", str(game), "--import"], capture_output=True)
    print(f"created {game}\nopen items right now (expected: theme, icon, assets, playtests, DOD.md):")
    import dod_check
    print("\n".join("  - " + p for p in dod_check.check(game)))
    print("\nnext: art direction (anchor asset first), then theme (build_theme.py), sfx.sh build, then build the game in game/ and run scripts/play.sh")
    return 0


if __name__ == "__main__":
    sys.exit(main())
