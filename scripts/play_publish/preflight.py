#!/usr/bin/env python3
"""Checks before a Play upload, so a release never goes out with a mistake that is cheap to catch.

  preflight.py <game-dir> [--platform android] [--offline] [--aab FILE]

Without --aab: checks the project (before the build).
With --aab:    checks the built bundle itself (the real proof: the AdMob app id inside its manifest).
Prints PASS / WARN / FAIL lines; exit 1 if anything FAILs. WARN never blocks.
"""
import json, re, subprocess, sys, urllib.request, zipfile
from pathlib import Path
from urllib.parse import urlparse

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
import dod_check, gf_status, store_listing_check  # noqa: E402

TEST_APP_PREFIX = "ca-app-pub-3940256099942544"


class Report:
    def __init__(self):
        self.rows = []

    def add(self, level, name, detail=""):
        self.rows.append((level, name, detail))
        print(f"{level:5} {name}" + (f": {detail}" if detail else ""))

    @property
    def failed(self):
        return any(l == "FAIL" for l, _, _ in self.rows)


def http_ok(url: str, timeout=15):
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "game-factory-preflight"})
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return r.status, r.read(4000).decode("utf-8", "replace")
    except Exception as e:
        return 0, str(e)


def android_section(text: str) -> str:
    i = text.find('platform="Android"')
    return text[i:] if i >= 0 else ""


def check_project(game: Path, platform: str, offline: bool, rep: Report) -> None:
    fails = dod_check.check(game, release=True, platforms=(platform,))
    if fails:
        for f in fails:
            rep.add("FAIL", "definition of done", f)
    else:
        rep.add("PASS", "definition of done", f"all automated checks pass for {platform}")

    bid_file = game / "bundle_id.txt"
    bundle = bid_file.read_text().strip() if bid_file.is_file() else ""
    presets = (game / "export_presets.cfg").read_text() if (game / "export_presets.cfg").is_file() else ""
    a = android_section(presets)
    pkg = (re.search(r'^package/unique_name="([^"]*)"', a, re.M) or [None, ""])[1]
    if not bundle or pkg != bundle:
        rep.add("FAIL", "package name", f"bundle_id.txt '{bundle}' vs Android preset '{pkg}'")
    else:
        rep.add("PASS", "package name", bundle)
    if 'platform="Android"' not in presets or "use_gradle_build=true" not in a:
        rep.add("FAIL", "android preset", "missing, or Gradle build is off (needed for AdMob and Firebase)")
    gs = game / "google-services.json"
    if (game / "addons" / "godotx_firebase").is_dir():
        try:
            pkgs = [c["client_info"]["android_client_info"]["package_name"] for c in json.loads(gs.read_text()).get("client", [])]
            rep.add("PASS" if pkgs == [bundle] else "WARN", "google-services.json",
                    "only this game's client entry" if pkgs == [bundle] else f"clients {pkgs}; keep only {bundle}")
            if bundle not in pkgs:
                rep.add("FAIL", "google-services.json", f"no client entry for {bundle}")
        except Exception as e:
            rep.add("FAIL", "google-services.json", f"missing or unreadable ({e})")

    code = int((re.search(r'^version/code=(\d+)', a, re.M) or [0, 0])[1])
    st = gf_status.load(game)
    last = int(st["play"].get("build") or 0)
    if st["play"]["state"] != "none" and code <= last:
        rep.add("WARN", "version code", f"{code} was already uploaded to Play ({st['play']['state']}); ship.sh bumps it for an update")
    else:
        rep.add("PASS", "version code", f"{code} (Play has {last or 'nothing'})")

    listing = game / "store" / "listing.json"
    try:
        problems = store_listing_check.check(json.loads(listing.read_text()))
        rep.add("FAIL" if problems else "PASS", "listing texts", "; ".join(problems) if problems else "within store limits")
    except Exception as e:
        rep.add("FAIL", "listing texts", f"store/listing.json: {e}")
    for k in ("play",):
        out = game / "store" / "out"
        miss = [n for n, ok in (("feature graphic", (out / "play_feature_1024x500.png").is_file()),
                                ("icon", (out / "icons" / "play_512.png").is_file()),
                                ("phone screenshots", any((out / "play").glob("*/phone/*.png")))) if not ok]
        rep.add("FAIL" if miss else "PASS", "store graphics", ("missing: " + ", ".join(miss)) if miss else "icon, feature graphic, screenshots present")

    if not offline:
        for key in ("privacy_url", "support_url"):
            u = st.get(key, "")
            if not u:
                rep.add("FAIL", key, "empty in store/status.json (deploy the site with publish_new.sh first)")
                continue
            code_, _ = http_ok(u)
            rep.add("PASS" if code_ == 200 else "FAIL", key, f"{u} -> {code_ or 'unreachable'}")
        pub = re.search(r"ca-app-pub-(\d+)", st["admob"].get("android_app_id", ""))
        if pub and st.get("privacy_url"):
            host = urlparse(st["privacy_url"])
            c, body = http_ok(f"{host.scheme}://{host.netloc}/app-ads.txt")
            ok = c == 200 and f"pub-{pub.group(1)}" in body
            rep.add("PASS" if ok else "WARN", "app-ads.txt", f"{host.netloc}/app-ads.txt " + ("lists your AdMob publisher id" if ok else f"missing or without pub-{pub.group(1)} ({c})"))

    key = Path.home() / ".game-factory" / "play-service-account.json"
    rep.add("PASS" if key.is_file() else "FAIL", "Play service account key", str(key) if key.is_file() else f"missing {key} (see skills/store-release/playbooks/fastlane.md)")
    ks = list((Path.home() / ".game-factory" / "keystores").glob("*.keystore")) if (Path.home() / ".game-factory" / "keystores").is_dir() else []
    rep.add("PASS" if ks else "FAIL", "upload keystore", ks[0].name if ks else "no keystore in ~/.game-factory/keystores")
    try:
        dirty = subprocess.run(["git", "-C", str(game), "status", "--short", "."], capture_output=True, text=True, timeout=10).stdout.strip()
        rep.add("WARN" if dirty else "PASS", "git", f"{len(dirty.splitlines())} uncommitted change(s) in this game, commit before shipping" if dirty else "clean")
    except Exception:
        pass


def check_aab(game: Path, aab: Path, rep: Report) -> None:
    if not aab.is_file():
        rep.add("FAIL", "aab", f"{aab} does not exist")
        return
    rep.add("PASS", "aab", f"{aab.name} ({aab.stat().st_size // 1_000_000} MB)")
    try:
        with zipfile.ZipFile(aab) as z:
            manifest = z.read("base/manifest/AndroidManifest.xml")
    except Exception as e:
        rep.add("FAIL", "aab manifest", str(e))
        return
    text = manifest.decode("latin-1")
    st = gf_status.refresh_ids(gf_status.load(game), game)
    live = st["admob"]["android_app_id"]
    if (game / "addons" / "admob").is_dir():
        if TEST_APP_PREFIX in text:
            rep.add("FAIL", "aab admob app id", "the bundle still carries Google's TEST app id (project.godot [admob] was reset? check it and rebuild)")
        elif live and live in text:
            rep.add("PASS", "aab admob app id", f"{live} is inside the manifest")
        else:
            rep.add("FAIL", "aab admob app id", "the project's AdMob app id is not in the bundle manifest")
    pkg = game.joinpath("bundle_id.txt").read_text().strip()
    rep.add("PASS" if pkg in text else "FAIL", "aab package", pkg)


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    if not args:
        sys.exit(__doc__)
    game = Path(args[0]).resolve()
    platform = sys.argv[sys.argv.index("--platform") + 1] if "--platform" in sys.argv else "android"
    rep = Report()
    if "--aab" in sys.argv:
        aab = Path(sys.argv[sys.argv.index("--aab") + 1])
        args = [a for a in args if a != str(aab)]
        check_aab(game, aab, rep)
    else:
        check_project(game, platform, "--offline" in sys.argv, rep)
    sys.exit(1 if rep.failed else 0)
