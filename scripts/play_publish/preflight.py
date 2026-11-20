#!/usr/bin/env python3
"""Checks before a Play upload, so a release never goes out with a mistake that is cheap to catch.

  preflight.py <game-dir> [--platform android|ios] [--offline] [--reuse-build] [--aab FILE]

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


def preset_section(text: str, platform_name: str) -> str:
    i = text.find(f'platform="{platform_name}"')
    return text[i:] if i >= 0 else ""


def read_env_file(path: Path) -> dict:
    out = {}
    if path.is_file():
        for line in path.read_text().splitlines():
            m = re.match(r'\s*export\s+(\w+)=(?:"([^"]*)"|(\S*))', line)
            if m:
                out[m.group(1)] = (m.group(2) if m.group(2) is not None else m.group(3)).replace("$HOME", str(Path.home()))
    return out


def check_common(game: Path, platform: str, offline: bool, rep: Report) -> dict:
    fails = dod_check.check(game, release=True, platforms=(platform,))
    if fails:
        for f in fails:
            rep.add("FAIL", "definition of done", f)
    else:
        rep.add("PASS", "definition of done", f"all automated checks pass for {platform}")
    bid_file = game / "bundle_id.txt"
    bundle = bid_file.read_text().strip() if bid_file.is_file() else ""
    presets = (game / "export_presets.cfg").read_text() if (game / "export_presets.cfg").is_file() else ""
    st = gf_status.load(game)
    listing = game / "store" / "listing.json"
    try:
        problems = store_listing_check.check(json.loads(listing.read_text()))
        rep.add("FAIL" if problems else "PASS", "listing texts", "; ".join(problems) if problems else "within store limits")
    except Exception as e:
        rep.add("FAIL", "listing texts", f"store/listing.json: {e}")
    if not offline:
        for key in ("privacy_url", "support_url"):
            u = st.get(key, "")
            if not u:
                rep.add("FAIL", key, "empty in store/status.json (deploy the site with publish_new.sh first)")
                continue
            code_, _ = http_ok(u)
            rep.add("PASS" if code_ == 200 else "FAIL", key, f"{u} -> {code_ or 'unreachable'}")
        pub = re.search(r"ca-app-pub-(\d+)", st["admob"].get("android_app_id", "") or st["admob"].get("ios_app_id", ""))
        if pub and st.get("privacy_url"):
            host = urlparse(st["privacy_url"])
            c, body = http_ok(f"{host.scheme}://{host.netloc}/app-ads.txt")
            ok = c == 200 and f"pub-{pub.group(1)}" in body
            rep.add("PASS" if ok else "WARN", "app-ads.txt", f"{host.netloc}/app-ads.txt " + ("lists your AdMob publisher id" if ok else f"missing or without pub-{pub.group(1)} ({c})"))
    try:
        dirty = subprocess.run(["git", "-C", str(game), "status", "--short", "."], capture_output=True, text=True, timeout=10).stdout.strip()
        rep.add("WARN" if dirty else "PASS", "git", f"{len(dirty.splitlines())} uncommitted change(s) in this game, commit before shipping" if dirty else "clean")
    except Exception:
        pass
    return {"bundle": bundle, "presets": presets, "status": st}


def check_android(game: Path, ctx: dict, rep: Report) -> None:
    bundle, presets, st = ctx["bundle"], ctx["presets"], ctx["status"]
    a = preset_section(presets, "Android")
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
    last = int(st["play"].get("build") or 0)
    if st["play"]["state"] != "none" and code <= last:
        rep.add("WARN", "version code", f"{code} was already uploaded to Play ({st['play']['state']}); ship.sh bumps it for an update")
    else:
        rep.add("PASS", "version code", f"{code} (Play has {last or 'nothing'})")
    out = game / "store" / "out"
    miss = [n for n, ok in (("feature graphic", (out / "play_feature_1024x500.png").is_file()),
                            ("icon", (out / "icons" / "play_512.png").is_file()),
                            ("phone screenshots", any((out / "play").glob("*/phone/*.png")))) if not ok]
    rep.add("FAIL" if miss else "PASS", "store graphics", ("missing: " + ", ".join(miss)) if miss else "icon, feature graphic, screenshots present")
    key = Path.home() / ".game-factory" / "play-service-account.json"
    rep.add("PASS" if key.is_file() else "FAIL", "Play service account key", str(key) if key.is_file() else f"missing {key} (see skills/store-release/playbooks/fastlane.md)")
    ksd = Path.home() / ".game-factory" / "keystores"
    ks = list(ksd.glob("*.keystore")) if ksd.is_dir() else []
    rep.add("PASS" if ks else "FAIL", "upload keystore", ks[0].name if ks else "no keystore in ~/.game-factory/keystores")


def check_ios(game: Path, ctx: dict, rep: Report, reuse_build: bool = False) -> None:
    bundle, presets, st = ctx["bundle"], ctx["presets"], ctx["status"]
    i = preset_section(presets, "iOS")
    ios_bundle = (re.search(r'^application/bundle_identifier="([^"]*)"', i, re.M) or [None, ""])[1]
    if not bundle or ios_bundle != bundle:
        rep.add("FAIL", "bundle id", f"bundle_id.txt '{bundle}' vs iOS preset '{ios_bundle}'")
    else:
        rep.add("PASS", "bundle id", bundle)
    team = (re.search(r'^application/app_store_team_id="([^"]*)"', i, re.M) or [None, ""])[1]
    rep.add("PASS" if team else "FAIL", "team id in the iOS preset", "set" if team else "application/app_store_team_id is empty")
    short = (re.search(r'^application/short_version="([^"]*)"', i, re.M) or [None, ""])[1]
    build = int((re.search(r'^application/version="(\d+)"', i, re.M) or [None, 0])[1])
    last = int(st["apple"].get("build") or 0)
    if reuse_build:
        rep.add("PASS", "build number", f"{short} ({build}): reusing the build that is already uploaded (--no-build)")
    elif st["apple"]["state"] != "none" and last and build <= last:
        rep.add("FAIL", "build number", f"iOS build {build} was already uploaded ({st['apple']['state']}, build {last}); bump it first: release.py bump <game> patch")
    else:
        rep.add("PASS", "build number", f"{short} ({build}); Apple has {last or 'nothing recorded'}")
    plist = game / "GoogleService-Info.plist"
    if (game / "addons" / "godotx_firebase").is_dir():
        t = plist.read_text() if plist.is_file() else ""
        m = re.search(r"<key>BUNDLE_ID</key>\s*<string>([^<]*)</string>", t)
        rep.add("PASS" if m and m.group(1) == bundle else "FAIL", "GoogleService-Info.plist",
                "bundle id matches" if m and m.group(1) == bundle else "missing, or its BUNDLE_ID is not " + bundle)
    launch = re.search(r'^storyboard/custom_image@3x="res://([^"]*)"', i, re.M)
    if launch and not (game / launch.group(1)).is_file():
        rep.add("FAIL", "launch image", f"{launch.group(1)} is referenced by the iOS preset but missing")
    try:
        locales = sorted(json.loads((game / "store" / "listing.json").read_text()))
    except Exception:
        locales = []
    miss = []
    for loc in locales:
        for size in ("iphone_6.9", "iphone_6.3"):
            if not any((game / "store" / "out" / "apple" / loc / size).glob("*.png")):
                miss.append(f"{loc}/{size}")
    rep.add("FAIL" if miss or not locales else "PASS", "App Store screenshots", ("missing: " + ", ".join(miss)) if miss else f"6.9 and 6.3 inch sets for {', '.join(locales)}")
    env = read_env_file(Path.home() / ".game-factory" / "fastlane.env")
    keyfile = Path(env.get("GF_ASC_KEY_PATH", "")).expanduser() if env.get("GF_ASC_KEY_PATH") else None
    have = bool(env.get("GF_ASC_KEY_ID")) and bool(env.get("GF_ASC_ISSUER_ID")) and keyfile is not None and keyfile.is_file()
    rep.add("PASS" if have else "FAIL", "App Store Connect API key",
            "key id, issuer id and the .p8 file are set" if have else "not set up: see playbooks/fastlane.md (One-time setup, step 3); fastlane_setup.sh says what is missing")
    for tool in ("fastlane", "xcodebuild"):
        ok = subprocess.run(["which", tool], capture_output=True).returncode == 0
        rep.add("PASS" if ok else "FAIL", tool, "found" if ok else "not installed")
    try:
        ids = subprocess.run(["security", "find-identity", "-v", "-p", "codesigning"], capture_output=True, text=True, timeout=20).stdout
        ok = "Apple Development" in ids or "Apple Distribution" in ids or "iPhone" in ids
        rep.add("PASS" if ok else "WARN", "signing identity", "an Apple signing certificate is in the keychain" if ok else "none found (Xcode > Settings > Accounts > Manage Certificates)")
    except Exception:
        pass
    ff = game / "fastlane" / "Fastfile"
    rep.add("PASS" if ff.is_file() else "WARN", "fastlane project", "fastlane/Fastfile present" if ff.is_file() else "missing: ship.sh runs fastlane_prepare.py for you")


def check_project(game: Path, platform: str, offline: bool, rep: Report, reuse_build: bool = False) -> None:
    ctx = check_common(game, platform, offline, rep)
    if platform == "ios":
        check_ios(game, ctx, rep, reuse_build)
    else:
        check_android(game, ctx, rep)


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
        check_project(game, platform, "--offline" in sys.argv, rep, "--reuse-build" in sys.argv)
    sys.exit(1 if rep.failed else 0)
