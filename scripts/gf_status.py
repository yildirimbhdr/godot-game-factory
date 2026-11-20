#!/usr/bin/env python3
"""One status file per game: <game>/store/status.json (schema 2). Every tool reads and writes it through this module.

  gf_status.py show  <game>                       what each store has, version, ids, open manual steps
  gf_status.py table [workspace]                  one line per game (the "where is everything" view)
  gf_status.py init  <game>                       create or upgrade status.json (migrates old formats, adds the manual to-do list)
  gf_status.py todo  <game>                       the manual steps still open, grouped, with what to enter
  gf_status.py done  <game> <id> [<id> ...]       tick manual steps (ids from `todo`)
  gf_status.py set   <game> play|apple <state> [--version V] [--build N] [--track T] [--note TEXT] [--source S]

Schema 2 (same fields in every game):
  play / apple : state (none|uploaded|internal_test|in_review|live|rejected|removed), version, build, track, app_id,
                 verified_on (date), source (script|console|legacy note), note
  admob        : android_app_id, ios_app_id (read from project.godot), store_linked {android, ios}
  firebase     : project, android_app, ios_app (read from the config files)
  manual       : [{id, store, text, hint, done, done_on}] steps no API can do (forms, "Send for review", ...)
  legacy       : the old keys of a pre-schema-2 file, kept verbatim so nothing is lost
Only public identifiers are stored here (no passwords, keys, team ids).
"""
import json, re, sys, time
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

STATES = {"none", "uploaded", "internal_test", "in_review", "live", "rejected", "removed"}
TEST_APP_PREFIX = "ca-app-pub-3940256099942544"


def path(game: Path) -> Path:
    return game / "store" / "status.json"


def today() -> str:
    return time.strftime("%Y-%m-%d")


def _store() -> dict:
    return {"state": "none", "version": "", "build": 0, "track": "", "app_id": "", "verified_on": "", "source": "", "note": ""}


def _bundle_id(game: Path) -> str:
    bid = game / "bundle_id.txt"
    if bid.is_file():
        return bid.read_text().strip()
    presets = game / "export_presets.cfg"          # older games have no bundle_id.txt: read it from the export presets
    if presets.is_file():
        for key in ("package/unique_name", "application/bundle_identifier"):
            m = re.search(rf'^{re.escape(key)}="([^"]+)"', presets.read_text(), re.M)
            if m:
                return m.group(1)
    return ""


def empty(game: Path) -> dict:
    return {"schema": 2, "bundle_id": _bundle_id(game), "privacy_url": "", "support_url": "",
            "play": _store(), "apple": _store(),
            "admob": {"android_app_id": "", "ios_app_id": "", "store_linked": {"android": False, "ios": False}},
            "firebase": {"project": "", "android_app": "", "ios_app": ""}, "manual": [], "legacy": {}}


def _clean_url(u: str) -> str:
    return re.sub(r"^\(.*?\)\s*", "", u or "").strip()


def migrate_legacy(raw: dict, game: Path) -> dict:
    """Map the pre-schema-2 status.json formats onto schema 2. Unknown facts stay unknown (state none or a legacy note), never guessed."""
    d = empty(game)
    if raw.get("bundle_id"):
        d["bundle_id"] = raw["bundle_id"]
    d["privacy_url"], d["support_url"] = _clean_url(raw.get("privacy_url", "")), _clean_url(raw.get("support_url", ""))
    legacy = {k: v for k, v in raw.items() if k not in {"bundle_id", "privacy_url", "support_url"}}
    for k in ("play", "apple"):
        v = raw.get(k)
        if isinstance(v, dict):                       # snake-fill style: {"play": {"state": "free text"}}
            d[k]["note"] = str(v.get("state", ""))[:300]
            d[k]["app_id"] = str(v.get("app_id", ""))
            d[k]["source"] = "legacy note"
    if raw.get("play_app_id"):
        d["play"]["app_id"] = str(raw["play_app_id"])
    if raw.get("apple_app_id"):
        d["apple"]["app_id"] = str(raw["apple_app_id"])
    ps, asub = raw.get("play_submitted"), raw.get("apple_submitted")
    if ps is True:
        d["play"].update(state="in_review", source="legacy note", note="play_submitted was true in the old file; the real state was not verified")
    if asub is True:
        d["apple"].update(state="in_review", source="legacy note", note="apple_submitted was true in the old file; the real state was not verified")
    elif isinstance(asub, str) and asub:
        d["apple"].update(state="uploaded", source="legacy note", note=asub[:300])
        m = re.match(r"(\d+\.\d+\.\d+)\s*\((\d+)\)", asub)
        if m:
            d["apple"]["version"], d["apple"]["build"] = m.group(1), int(m.group(2))
    if raw.get("store_assets"):
        legacy["store_assets"] = raw["store_assets"]
    d["legacy"] = legacy
    return d


def load(game: Path) -> dict:
    p = path(game)
    if not p.is_file():
        return empty(game)
    raw = json.loads(p.read_text())
    if raw.get("schema") == 2:
        base = empty(game)
        for k, v in raw.items():
            base[k] = ({**base[k], **v} if isinstance(v, dict) and isinstance(base.get(k), dict) else v)
        return base
    return migrate_legacy(raw, game)


def save(game: Path, d: dict) -> None:
    p = path(game)
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(json.dumps(d, indent=2, ensure_ascii=False) + "\n")


def record_store(game: Path, store: str, state: str, version: str = "", build: int = 0, track: str = "",
                 source: str = "script", note: str = "") -> dict:
    assert store in {"play", "apple"} and state in STATES, (store, state)
    d = load(game)
    d[store].update(state=state, verified_on=today(), source=source)
    if version:
        d[store]["version"] = version
    if build:
        d[store]["build"] = int(build)
    d[store]["track"] = track
    if note:
        d[store]["note"] = note
    save(game, d)
    return d


# ---- facts read from the project (never typed by hand) -------------------------------------------------------------

def refresh_ids(d: dict, game: Path) -> dict:
    pg = game / "project.godot"
    if pg.is_file():
        ids = dict(re.findall(r'^general/(android|ios)/app_id="([^"]*)"', pg.read_text(), re.M))
        for k in ("android", "ios"):
            v = ids.get(k, "")
            d["admob"][f"{k}_app_id"] = "" if v.startswith(TEST_APP_PREFIX) else v      # Google's test id is not "the app's id"
    gs, plist = game / "google-services.json", game / "GoogleService-Info.plist"
    if gs.is_file():
        try:
            j = json.loads(gs.read_text())
            d["firebase"]["project"] = j.get("project_info", {}).get("project_id", d["firebase"]["project"])
            for c in j.get("client", []):
                info = c.get("client_info", {})
                if info.get("android_client_info", {}).get("package_name") == d["bundle_id"]:
                    d["firebase"]["android_app"] = info.get("mobilesdk_app_id", "")
        except ValueError:
            pass
    if plist.is_file():
        m = re.search(r"<key>GOOGLE_APP_ID</key>\s*<string>([^<]*)</string>", plist.read_text())
        if m:
            d["firebase"]["ios_app"] = m.group(1)
    presets = game / "export_presets.cfg"
    if presets.is_file():
        t = presets.read_text()
        a = t[t.find('platform="Android"'):] if 'platform="Android"' in t else ""
        v, c = re.search(r'^version/name="([^"]*)"', a, re.M), re.search(r'^version/code=(\d+)', a, re.M)
        d["dev_version"] = {"version": v.group(1) if v else "", "build": int(c.group(1)) if c else 0}
    return d


# ---- manual steps -------------------------------------------------------------------------------------------------

def _facts(game: Path) -> dict:
    import store_declarations
    f = store_declarations.detect(game)
    brief = store_declarations.read_brief(game)
    art = str((brief.get("art") or {}).get("source", "")).lower()
    f["generated_art"] = any(k in art for k in ("gemini", "pixellab", "ai", "generat"))
    return f


def manual_catalog(game: Path, d: dict) -> list:
    f = _facts(game)
    priv, sup = d.get("privacy_url") or "(deploy the privacy page first)", d.get("support_url") or ""
    items = [
        ("play.privacy_url", "play", "Play Console > App content: enter the privacy policy URL", priv),
        ("play.app_access", "play", "App content > App access: all functionality available without restrictions", "no login in the game"),
        ("play.ads", "play", "App content > Ads: " + ("Yes, the app contains ads" if f["ads"] else "No ads"), "see store/declarations.html"),
        ("play.content_rating", "play", "App content > Content rating: fill the IARC questionnaire (category Game)", "see store/declarations.html"),
        ("play.target_audience", "play", "App content > Target audience: 13+ (not for children)", "see store/declarations.html"),
        ("play.data_safety", "play", "App content > Data safety form", "see store/declarations.html"),
        ("play.store_settings", "play", "Store settings: category, contact email, website", "website: " + (sup or "your support page")),
    ]
    if f["generated_art"]:
        items.append(("play.ai_labels", "play", "Store listing: tick the AI-generated asset labels (icon, feature graphic, screenshots)", "every graphic that contains generated art"))
    items += [
        ("play.testers", "play", "Testing > Internal testing: add testers (emails) so you can install from Play", ""),
        ("play.countries", "play", "Production > Countries: select all, save", ""),
        ("play.send", "play", "Publishing overview: Send for review", "last step, always yours"),
    ]
    if f["ads"]:
        items += [
            ("admob.link_store", "admob", "AdMob > Apps: link the live Play listing to the app (ads are limited until then)", "only after the app is live on Play"),
            ("admob.app_ads", "admob", "AdMob > app-ads.txt shows 'found' (the Play listing website must be the site that serves /app-ads.txt)", "check a few days after launch"),
        ]
    if d["apple"]["state"] != "none":
        items += [
            ("apple.privacy_label", "apple", "App Store Connect > App Privacy: data types and privacy policy URL for every locale", "see store/declarations.html"),
            ("apple.age_rating", "apple", "App Information > Age Ratings questionnaire", "see store/declarations.html"),
            ("apple.review_info", "apple", "Version > App Review Information: name, phone, email", ""),
            ("apple.add_for_review", "apple", "Version: Add for Review / Submit", "last step, always yours"),
        ]
    return items


def ensure_manual(d: dict, game: Path) -> dict:
    have = {m["id"]: m for m in d.get("manual", [])}
    out = []
    for mid, store, text, hint in manual_catalog(game, d):
        m = have.get(mid, {"id": mid, "done": False, "done_on": ""})
        m.update(store=store, text=text, hint=hint)
        out.append(m)
    known = {m["id"] for m in out}
    out += [m for m in d.get("manual", []) if m["id"] not in known]      # keep custom items the user added
    # A store that already took the submission (in review / live) must have had its forms filled: mark those steps done,
    # flagged "inferred" so nobody mistakes them for a verified fact. AdMob linking and checks after launch stay open.
    for m in out:
        if not m["done"] and m["store"] in ("play", "apple") and d[m["store"]]["state"] in ("in_review", "live"):
            m["done"], m["done_on"] = True, "inferred from state " + d[m["store"]]["state"]
    d["manual"] = out
    return d


def init(game: Path) -> dict:
    d = ensure_manual(refresh_ids(load(game), game), game)
    d["schema"] = 2
    save(game, d)
    return d


def open_manual(d: dict) -> list:
    return [m for m in d.get("manual", []) if not m.get("done")]


# ---- views --------------------------------------------------------------------------------------------------------

def line(d: dict, name: str) -> str:
    def s(k):
        v = d[k]
        return f"{v['state']}" + (f" {v['version']}({v['build']})" if v["version"] else "") + (f" [{v['track']}]" if v["track"] else "")
    return f"{name:14} play: {s('play'):38} apple: {s('apple'):28} open steps: {len(open_manual(d))}"


def show(game: Path) -> None:
    d = refresh_ids(load(game), game)
    print(f"{game.name}  ({d['bundle_id']})")
    dev = d.get("dev_version", {})
    if dev:
        print(f"  in development: {dev['version']} (build {dev['build']})")
    for k, label in (("play", "Google Play"), ("apple", "App Store")):
        v = d[k]
        print(f"  {label:12} {v['state']}" + (f" {v['version']} (build {v['build']})" if v["version"] else "") + (f" [{v['track']}]" if v["track"] else "")
              + (f"   verified {v['verified_on']} via {v['source']}" if v["verified_on"] else "")
              + (f"\n               note: {v['note']}" if v["note"] else ""))
    a = d["admob"]
    print(f"  AdMob        android {a['android_app_id'] or '-'}   ios {a['ios_app_id'] or '-'}   store linked: {a['store_linked']}")
    print(f"  Firebase     {d['firebase']['project'] or '-'}  android {d['firebase']['android_app'] or '-'}  ios {d['firebase']['ios_app'] or '-'}")
    print(f"  privacy      {d['privacy_url'] or '-'}")
    todo(game, d, header=False)


def todo(game: Path, d: dict = None, header: bool = True) -> None:
    d = d or load(game)
    items = open_manual(d)
    if header:
        print(f"{game.name}: {len(items)} manual step(s) open")
    for store in ("play", "admob", "apple"):
        group = [m for m in items if m["store"] == store]
        if group:
            print(f"  [{store}]")
            for m in group:
                print(f"    {m['id']:24} {m['text']}" + (f"  ({m['hint']})" if m["hint"] else ""))
    if not items:
        print("  nothing open")


def games_in(workspace: Path) -> list:
    return sorted(p.parent for p in workspace.glob("*/project.godot"))


def main(argv: list) -> int:
    if len(argv) < 2:
        print(__doc__)
        return 1
    cmd = argv[1]
    if cmd == "table":
        ws = Path(argv[2] if len(argv) > 2 else ".").expanduser().resolve()
        for g in games_in(ws):
            print(line(refresh_ids(load(g), g), g.name))
        return 0
    game = Path(argv[2]).resolve()
    if cmd == "show":
        show(game)
    elif cmd == "init":
        d = init(game)
        print(f"wrote {path(game)} ({len(d['manual'])} manual steps)")
    elif cmd == "todo":
        todo(game)
    elif cmd == "done":
        d = load(game)
        ids = set(argv[3:])
        hit = 0
        for m in d["manual"]:
            if m["id"] in ids:
                m["done"], m["done_on"], hit = True, today(), hit + 1
        if hit != len(ids):
            print("unknown id(s): " + ", ".join(sorted(ids - {m['id'] for m in d['manual']})) + "  (run `init` first, see `todo`)")
            return 1
        save(game, d)
        todo(game, d)
    elif cmd == "set":
        store, state = argv[3], argv[4]
        if store not in {"play", "apple"} or state not in STATES:
            print(f"store must be play|apple, state one of {sorted(STATES)}")
            return 1
        opt = {argv[i]: argv[i + 1] for i in range(5, len(argv) - 1, 2)}
        record_store(game, store, state, opt.get("--version", ""), int(opt.get("--build", 0) or 0), opt.get("--track", ""),
                     opt.get("--source", "console"), opt.get("--note", ""))
        show(game)
    else:
        print(__doc__)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
