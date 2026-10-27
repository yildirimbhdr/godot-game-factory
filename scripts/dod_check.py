#!/usr/bin/env python3
"""Definition of Done gate for a Godot game project (automated half of the checklist).

  dod_check.py <project-dir> [--json] [--release]

Exit 0 when every automated check passes, 1 otherwise (failures printed one per line).
Checks (see skills/playtest-verify for the manual half that DOD.md records):
  identity   a game-specific theme (not FACTORY_DEFAULT) and an app icon that is not the template icon.svg
  assets     every file under assets/ is covered by ASSETS.md (path, folder or file name)
  audio      every AudioManager.play_sfx("name") in code has assets/audio/sfx/name.*
  splash     the engine boot splash (Godot logo) is off or replaced, and the main scene is the game's own splash screen
  playtest   .playtest/dod_stamp.json has strict-audio runs of a `smoke*` scenario at >= 3 screen shapes,
             all newer than the newest source file
  review     DOD.md exists, has no unchecked box and is newer than the newest source file
  plan       if PLAN.md exists (games started with /new-game): it must carry an "Approved: <date>" line;
             with --release phases 1-8 must be ticked
  monetize   if addons/admob is installed: the Ads and Analytics autoloads are the real ones (not the mock);
             with --release also: every LIVE_UNITS id is filled and the AdMob app id is not Google's test id
"""
import json, re, sys, time
from pathlib import Path

IGNORE_DIRS = {".godot", ".playtest", ".git", "build", "tools", "theme_src", "node_modules"}
SOURCE_EXT = {".gd", ".tscn", ".tres", ".cfg", ".png", ".ogg", ".wav", ".mp3", ".ttf", ".svg"}


def sources(project: Path):
    for p in project.rglob("*"):
        if not p.is_file() or any(part in IGNORE_DIRS for part in p.relative_to(project).parts):
            continue
        if p.suffix in SOURCE_EXT or p.name == "project.godot":
            yield p


def newest_source(project: Path) -> float:
    return max((p.stat().st_mtime for p in sources(project)), default=0.0)


def check_monetization(project: Path, release: bool) -> list[str]:
    fails = []
    if not (project / "addons" / "admob").is_dir():
        return fails
    ads = project / "autoload" / "ads.gd"
    ads_text = ads.read_text() if ads.is_file() else ""
    if 'provider := "none"' in ads_text and "MobileAds" not in ads_text:
        fails.append("monetize: addons/admob is installed but autoload/ads.gd is still the mock (copy templates/modules/ads-admob/ads.gd)")
    ana = project / "autoload" / "analytics.gd"
    if not ana.is_file() or "GodotxFirebaseAnalytics" not in ana.read_text():
        fails.append("monetize: autoload/analytics.gd is missing or still the mock (copy templates/modules/ads-admob/analytics.gd)")
    if release:
        live = re.search(r"const LIVE_UNITS := \{(.*?)\n\}", ads_text, re.S)
        uses_inter = any(re.search(r"\b(try|show)_interstitial\(", p.read_text(errors="ignore")) for p in project.rglob("*.gd")
                         if ".godot" not in p.parts and "addons" not in p.parts and p.name != "ads.gd" and p.name != "check_ads.gd")
        block = live.group(1) if live else ""
        if not uses_inter:   # a rewarded-only game does not need interstitial ids
            block = re.sub(r'"interstitial":[^\n]*', "", block)
        if not live or re.search(r'""', block):
            fails.append("monetize(release): LIVE_UNITS in autoload/ads.gd still has empty ad unit ids")
        ids = dict(re.findall(r'^general/(android|ios)/app_id="([^"]*)"', (project / "project.godot").read_text(), re.M))
        for platform in ("android", "ios"):
            app_id = ids.get(platform, "")
            if not app_id or app_id.startswith("ca-app-pub-3940256099942544"):
                fails.append(f"monetize(release): [admob] general/{platform}/app_id in project.godot is missing or Google's test app id")
    return fails


def check_plan(project: Path, release: bool) -> list[str]:
    plan = project / "PLAN.md"
    if not plan.is_file():
        return []   # older games and bare projects have no plan file
    text = plan.read_text()
    fails = []
    if not re.search(r"^Approved: \d{4}-\d{2}-\d{2}", text, re.M):
        fails.append("plan: PLAN.md has no 'Approved: <date>' line (the user must approve the brief before any game code)")
    if release:
        open_phases = [m for m in re.findall(r"^- \[ \] (\d+)\.", text, re.M) if int(m) <= 8]
        if open_phases:
            fails.append(f"plan(release): PLAN.md phases not done yet: {', '.join(open_phases)}")
    return fails


def check(project: Path, release: bool = False) -> list[str]:
    fails = []
    pg = project / "project.godot"
    if not pg.is_file():
        return [f"{project} is not a Godot project (no project.godot)"]
    text = pg.read_text()

    theme = re.search(r'theme/custom="([^"]*)"', text)
    if not theme or "theme_default" in theme.group(1):
        fails.append("identity: project still uses the template theme_default.tres (build a game theme)")
    elif (project / theme.group(1).replace("res://", "")).is_file() and "FACTORY_DEFAULT" in (project / theme.group(1).replace("res://", "")).read_text():
        fails.append("identity: theme resource is still named FACTORY_DEFAULT")
    icon = re.search(r'config/icon="([^"]*)"', text)
    if not icon or icon.group(1).endswith("icon.svg"):
        fails.append("identity: application icon is still the template icon.svg")

    if re.search(r"^boot_splash/show_image=false", text, re.M) is None and not re.search(r'^boot_splash/image="', text, re.M):
        fails.append("splash: the Godot boot logo still shows (set boot_splash/show_image=false, or boot_splash/image to the game logo)")
    main = re.search(r'run/main_scene="res://([^"]*)"', text)
    # A game may skip its own splash when the platform launch screens carry the logo (iOS: storyboard/custom_image@3x in the preset): one logo screen, not two.
    presets = (project / "export_presets.cfg").read_text(errors="ignore") if (project / "export_presets.cfg").is_file() else ""
    launch_logo = "storyboard/custom_image@3x=" in presets
    if not main or not (project / main.group(1)).is_file() or ("splash" not in main.group(1).lower() and not launch_logo):
        fails.append("splash: run/main_scene must be the game's own splash scene (copy ui/splash.tscn from the template; it leads to the main menu)")

    assets = project / "assets"
    ledger = (project / "ASSETS.md").read_text() if (project / "ASSETS.md").is_file() else ""
    if not ledger:
        fails.append("assets: ASSETS.md is missing")
    elif assets.is_dir():
        for f in assets.rglob("*"):
            if not f.is_file() or f.suffix in {".import", ".uid"} or f.name.startswith("."):
                continue
            rel = str(f.relative_to(project))
            if rel not in ledger and str(f.parent.relative_to(project)) not in ledger and f.name not in ledger and f.stem not in ledger:
                fails.append(f"assets: {rel} is not listed in ASSETS.md")

    sfx_dir = assets / "audio" / "sfx"
    have = {p.stem for p in sfx_dir.glob("*") if p.suffix in {".wav", ".ogg", ".mp3"}} if sfx_dir.is_dir() else set()
    used = set()
    for gd in project.rglob("*.gd"):
        if any(part in IGNORE_DIRS for part in gd.relative_to(project).parts):
            continue
        used |= set(re.findall(r'play_sfx\("([A-Za-z0-9_]+)"', gd.read_text()))
    for name in sorted(used - have):
        fails.append(f"audio: play_sfx(\"{name}\") has no file in assets/audio/sfx")
    if not have:
        fails.append("audio: no sound effects at all in assets/audio/sfx")

    newest = newest_source(project)
    stamp_file = project / ".playtest" / "dod_stamp.json"
    runs = json.loads(stamp_file.read_text()).get("runs", {}) if stamp_file.is_file() else {}
    fresh = {k.split("@", 1)[1] for k, t in runs.items() if k.startswith("smoke") and t >= newest}
    if len(fresh) < 3:
        fails.append(f"playtest: need strict-audio `smoke*` runs at 3 screen shapes newer than the last edit, have {sorted(fresh) or 'none'} "
                     "(run scripts/playtest.sh at default, --resolution 450x975 --notch, --resolution 600x800)")

    fails += check_plan(project, release)
    fails += check_monetization(project, release)

    dod = project / "DOD.md"
    if not dod.is_file():
        fails.append("review: DOD.md is missing (copy templates/godot-base/DOD.md and fill it after looking at the screenshots)")
    else:
        unchecked = re.findall(r"^\s*- \[ \]", dod.read_text(), re.M)
        if unchecked:
            fails.append(f"review: DOD.md has {len(unchecked)} unchecked item(s)")
        if dod.stat().st_mtime < newest:
            fails.append("review: DOD.md is older than the latest edit; re-review and update it")
    return fails


if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    proj = Path(sys.argv[1]).resolve()
    problems = check(proj, "--release" in sys.argv)
    if "--json" in sys.argv:
        print(json.dumps({"project": str(proj), "ok": not problems, "failures": problems}))
    else:
        print("\n".join(problems) if problems else "Definition of Done: all automated checks pass")
    sys.exit(1 if problems else 0)
