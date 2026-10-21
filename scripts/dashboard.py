#!/usr/bin/env python3
"""Publisher dashboard: one offline HTML page showing the user's profile and every game in their workspace.

  dashboard.py [workspace-dir] [--open] [--out file.html]

Reads only files on this machine (the profile from gf_profile.py, each game's project.godot, export_presets.cfg, store/,
DOD.md, git) and writes ~/.game-factory/dashboard.html. Nothing is uploaded and the page makes no network requests.
A game is any folder in the workspace with a project.godot. Passwords and keys are never read; the page shows only
public identifiers (bundle ids, ad/Firebase app ids, project ids).
"""
import html, json, re, subprocess, sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import gf_profile, dod_check, store_listing_check  # noqa: E402


def cfg_value(text: str, key: str, default=""):
    m = re.search(rf'^{re.escape(key)}="?([^"\n]*)"?\s*$', text, re.M)
    return m.group(1) if m else default


def section_value(text: str, section: str, key: str, default=""):
    m = re.search(rf"^\[{re.escape(section)}\]\n(.*?)(?=^\[|\Z)", text, re.M | re.S)
    return cfg_value(m.group(1), key, default) if m else default


def git(game: Path, *args) -> str:
    try:
        return subprocess.run(["git", "-C", str(game), *args], capture_output=True, text=True, timeout=10).stdout.strip()
    except Exception:
        return ""


def png_count(d: Path) -> int:
    return len([p for p in d.rglob("*.png")]) if d.is_dir() else 0


def inspect(game: Path) -> dict:
    pg = (game / "project.godot").read_text()
    presets = (game / "export_presets.cfg").read_text() if (game / "export_presets.cfg").is_file() else ""
    g = {"folder": game.name, "name": cfg_value(pg, "config/name", game.name)}
    g["ios_bundle"] = cfg_value(presets, "application/bundle_identifier")
    g["android_package"] = cfg_value(presets, "package/unique_name")
    g["version"] = cfg_value(presets, "version/name") or cfg_value(presets, "application/short_version")
    admob = re.search(r"^\[admob\]\n(.*?)(?=^\[|\Z)", pg, re.M | re.S)
    ids = dict(re.findall(r'^general/(android|ios)/app_id="([^"]*)"', admob.group(1), re.M)) if admob else {}
    g["admob"] = ids
    g["ads_module"] = (game / "addons" / "admob").is_dir()
    g["firebase_module"] = (game / "addons" / "godotx_firebase").is_dir()
    plist = game / "GoogleService-Info.plist"
    g["firebase"] = {}
    if plist.is_file():
        t = plist.read_text()
        for k, label in (("PROJECT_ID", "project"), ("GOOGLE_APP_ID", "ios_app")):
            m = re.search(rf"<key>{k}</key>\s*<string>([^<]*)</string>", t)
            if m:
                g["firebase"][label] = m.group(1)
    gs = game / "google-services.json"
    if gs.is_file():
        m = re.search(r'"mobilesdk_app_id":\s*"([^"]+)"', gs.read_text())
        if m:
            g["firebase"]["android_app"] = m.group(1)
    # state
    fails = dod_check.check(game)
    release_fails = [f for f in dod_check.check(game, release=True) if f.startswith("monetize(release)")]
    g["dod_fails"] = fails
    g["release_fails"] = release_fails
    dod = game / "DOD.md"
    if dod.is_file():
        t = dod.read_text()
        g["dod_done"], g["dod_total"] = len(re.findall(r"^\s*- \[x\]", t, re.M)), len(re.findall(r"^\s*- \[[ x]\]", t, re.M))
    store = game / "store"
    s = {"has_store": store.is_dir()}
    if store.is_dir():
        out = store / "out"
        s["icons"] = png_count(out / "icons")
        s["feature"] = (out / "play_feature_1024x500.png").is_file()
        s["screens_apple"] = png_count(out / "apple")
        s["screens_play"] = png_count(out / "play")
        if (store / "listing.json").is_file():
            try:
                s["listing_problems"] = store_listing_check.check(json.loads((store / "listing.json").read_text()))
                s["locales"] = sorted(json.loads((store / "listing.json").read_text()))
            except Exception as e:
                s["listing_problems"] = [str(e)]
        pol = store / "policy.json"
        s["policy_json"] = json.loads(pol.read_text()) if pol.is_file() else {}
        s["policy_page"] = (out / "privacy" / "index.html").is_file()
        s["builds"] = sorted(p.name for p in (store / "builds").glob("*") if p.suffix in {".aab", ".apk", ".ipa"}) if (store / "builds").is_dir() else []
        s["status"] = json.loads((store / "status.json").read_text()) if (store / "status.json").is_file() else {}
    g["store"] = s
    g["git"] = {"commit": git(game, "log", "-1", "--format=%h %s"), "dirty": bool(git(game, "status", "--short"))} if (game / ".git").is_dir() else None
    ledger = Path.home() / ".game-factory" / "genart_ledger.json"
    return g


def esc(x) -> str:
    return html.escape(str(x))


def pill(ok, yes="ok", no="open") -> str:
    return f'<span class="pill {"ok" if ok else "open"}">{esc(yes if ok else no)}</span>'


def kv(label, value) -> str:
    return f'<div class="kv"><span>{esc(label)}</span><b>{esc(value) if value else "-"}</b></div>'


def card(g: dict) -> str:
    s = g["store"]
    rows = [kv("iOS bundle", g["ios_bundle"]), kv("Android package", g["android_package"]), kv("Version", g["version"])]
    ads = g["admob"]
    rows += [kv("AdMob iOS app", ads.get("ios", "")), kv("AdMob Android app", ads.get("android", ""))]
    fb = g["firebase"]
    rows += [kv("Firebase project", fb.get("project", "")), kv("Firebase iOS app", fb.get("ios_app", "")), kv("Firebase Android app", fb.get("android_app", ""))]
    checks = [
        ("Definition of Done", not g["dod_fails"], f'{len(g["dod_fails"])} open'),
        ("Ads + analytics modules", g["ads_module"] and g["firebase_module"], "not installed"),
        ("Live ad ids set", g["ads_module"] and not g["release_fails"], "test ids only"),
        ("Store graphics", bool(s.get("icons")) and s.get("feature") and bool(s.get("screens_play")), "not built"),
        ("Listing texts valid", bool(s.get("locales")) and not s.get("listing_problems"), "missing or too long"),
        ("Privacy policy page built", s.get("policy_page", False), "not built"),
        ("Release build", bool(s.get("builds")), "none"),
    ]
    st = s.get("status", {})
    for key, label in (("privacy_url", "Privacy policy URL live"), ("play_submitted", "Submitted to Google Play"), ("apple_submitted", "Submitted to App Store")):
        checks.append((label, bool(st.get(key)), "no"))
    done = sum(1 for _, ok, _ in checks if ok)
    lis = "".join(f'<li>{pill(ok, "done", why)} {esc(name)}</li>' for name, ok, why in checks)
    extra = ""
    if s.get("builds"):
        extra += f'<p class="small">Builds: {esc(", ".join(s["builds"]))}</p>'
    if st.get("privacy_url"):
        extra += f'<p class="small">Privacy URL: {esc(st["privacy_url"])}</p>'
    if g["git"]:
        extra += f'<p class="small">git: {esc(g["git"]["commit"])}{" (uncommitted changes)" if g["git"]["dirty"] else ""}</p>'
    if g["dod_fails"]:
        extra += "<details><summary>Definition of Done: open items</summary><ul>" + "".join(f"<li>{esc(f)}</li>" for f in g["dod_fails"]) + "</ul></details>"
    return (f'<article class="game"><header><h3>{esc(g["name"])}</h3><span class="prog">{done}/{len(checks)}</span></header>'
            f'<div class="bar"><i style="width:{100 * done // len(checks)}%"></i></div>'
            f'<div class="cols"><div>{"".join(rows)}</div><ul class="checks">{lis}</ul></div>{extra}</article>')


CSS = """
:root{--bg:#fff8f0;--fg:#2b2540;--mut:#7a6f99;--card:#fff;--line:#e4d6fa;--acc:#5b4b8a;--ok:#2f8f5b;--open:#b0772a}
@media (prefers-color-scheme:dark){:root{--bg:#1c1830;--fg:#efeaff;--mut:#a79fc9;--card:#27223f;--line:#3b3460;--acc:#c7b6ff;--ok:#6fd49b;--open:#f0b862}}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--fg);font:16px/1.5 system-ui,sans-serif}
main{max-width:1000px;margin:0 auto;padding:24px 16px 48px}h1{color:var(--acc);margin:.2em 0}h2{margin:1.6em 0 .6em;color:var(--acc)}
.note{color:var(--mut);font-size:14px}.profile,.game{background:var(--card);border:1px solid var(--line);border-radius:16px;padding:16px 18px;margin:12px 0}
.kv{display:flex;justify-content:space-between;gap:12px;padding:3px 0;border-bottom:1px dashed var(--line)}.kv span{color:var(--mut)}.kv b{font-weight:600;text-align:right;word-break:break-all}
.game header{display:flex;justify-content:space-between;align-items:baseline}.game h3{margin:0}.prog{color:var(--mut)}
.bar{height:8px;background:var(--line);border-radius:6px;margin:8px 0 14px}.bar i{display:block;height:100%;background:var(--ok);border-radius:6px}
.cols{display:grid;grid-template-columns:1fr 1fr;gap:20px}@media(max-width:720px){.cols{grid-template-columns:1fr}}
.checks{list-style:none;margin:0;padding:0}.checks li{padding:3px 0}.pill{display:inline-block;font-size:12px;padding:1px 8px;border-radius:99px;margin-right:6px;color:#fff}
.pill.ok{background:var(--ok)}.pill.open{background:var(--open)}.small{color:var(--mut);font-size:13px;margin:.5em 0 0}details{margin-top:8px;font-size:14px}
"""


def build(workspace: Path) -> str:
    prof = gf_profile.load()
    games = [inspect(p.parent) for p in sorted(workspace.glob("*/project.godot"))]
    prof_rows = "".join(kv(k.replace("_", " "), json.dumps(v, ensure_ascii=False) if isinstance(v, list) else v)
                        for k, v in prof.items() if k != "android_keychain_service")
    prof_rows += kv("Android keystore password", "in the macOS Keychain (not shown)")
    body = (f'<h1>Game factory dashboard</h1><p class="note">Built from files on this computer. Nothing here is uploaded. '
            f'To change a profile value ask Claude or run <code>scripts/gf_profile.py set &lt;key&gt; &lt;value&gt;</code>.</p>'
            f'<h2>Publisher profile</h2><section class="profile">{prof_rows}</section>'
            f'<h2>Games ({len(games)})</h2>{"".join(card(g) for g in games) or "<p>No game with a project.godot in this workspace.</p>"}')
    return f'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Game factory dashboard</title><style>{CSS}</style></head><body><main>{body}</main></body></html>'


if __name__ == "__main__":
    argv = sys.argv[1:]
    out = Path.home() / ".game-factory" / "dashboard.html"
    if "--out" in argv:
        i = argv.index("--out")
        out = Path(argv[i + 1])
        del argv[i:i + 2]
    args = [a for a in argv if not a.startswith("--")]
    ws = Path(args[0]).expanduser() if args else Path(gf_profile.load()["workspace"] or ".").expanduser()
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(build(ws.resolve()), encoding="utf-8")
    print("wrote", out)
    if "--open" in sys.argv:
        subprocess.run(["open", str(out)])
