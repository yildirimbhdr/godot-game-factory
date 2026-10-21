#!/usr/bin/env python3
"""Version and release tracking for a game: one place that knows what is in development and what each store has.

  release.py show <game>
  release.py note <game> "text"                   add a line to CHANGELOG.md under Unreleased
  release.py bump <game> major|minor|patch        new version + next build number, written into export_presets.cfg,
                                                  CHANGELOG.md (Unreleased becomes the new version) and store/releases.json
  release.py store <game> play|apple <state> [--version V] [--build N] [--track internal|closed|production]
                                                  record what a store has; states: uploaded, internal_test, in_review, live, rejected, removed

Versioning (semantic): patch = fixes and tuning, minor = new levels, worlds or features, major = redesign or a new
core loop. The build number (Android version/code, iOS CFBundleVersion) rises on every bump and never goes back, for
both stores, because the stores reject a build number they have seen before.
store/releases.json is the source of truth the dashboard reads. Stores are only ever recorded here after the
user (or Claude with the user's go-ahead) actually did the step in the store console.
"""
import json, re, sys, time
from pathlib import Path

STATES = {"uploaded", "internal_test", "in_review", "live", "rejected", "removed"}


def paths(game: Path):
    return game / "export_presets.cfg", game / "store" / "releases.json", game / "CHANGELOG.md"


def load(game: Path) -> dict:
    presets, rel, _ = paths(game)
    if rel.is_file():
        return json.loads(rel.read_text())
    text = presets.read_text()
    m = re.search(r'^version/name="([^"]*)"', text[text.find('name="Android Release"'):], re.M)
    c = re.search(r'^version/code=(\d+)', text[text.find('name="Android Release"'):], re.M)
    return {"version": m.group(1) if m else "1.0.0", "build": int(c.group(1)) if c else 1, "history": [], "stores": {}}


def save(game: Path, d: dict):
    _, rel, _ = paths(game)
    rel.parent.mkdir(exist_ok=True)
    rel.write_text(json.dumps(d, indent=2, ensure_ascii=False) + "\n")


def write_presets(game: Path, version: str, build: int):
    p = paths(game)[0]
    t = p.read_text()
    t = re.sub(r'^(version/name=)".*"$', rf'\1"{version}"', t, flags=re.M)
    t = re.sub(r'^(version/code=)\d+$', rf'\g<1>{build}', t, flags=re.M)
    t = re.sub(r'^(application/short_version=)".*"$', rf'\1"{version}"', t, flags=re.M)
    t = re.sub(r'^(application/version=)".*"$', rf'\1"{build}"', t, flags=re.M)
    p.write_text(t)


def bump_version(v: str, part: str) -> str:
    a, b, c = (int(x) for x in v.split("."))
    return {"major": f"{a + 1}.0.0", "minor": f"{a}.{b + 1}.0", "patch": f"{a}.{b}.{c + 1}"}[part]


def changelog_note(game: Path, text: str):
    cl = paths(game)[2]
    s = cl.read_text() if cl.is_file() else "# Changelog\n\n## Unreleased\n\n"
    if "## Unreleased" not in s:
        s = s.replace("# Changelog\n", "# Changelog\n\n## Unreleased\n", 1)
    s = s.replace("## Unreleased\n", f"## Unreleased\n- {text}\n", 1)
    cl.write_text(s)


def changelog_release(game: Path, version: str) -> list:
    cl = paths(game)[2]
    s = cl.read_text() if cl.is_file() else "# Changelog\n\n## Unreleased\n\n"
    m = re.search(r"## Unreleased\n(.*?)(?=^## |\Z)", s, re.M | re.S)
    notes = [l[2:].strip() for l in (m.group(1) if m else "").splitlines() if l.startswith("- ")]
    s = re.sub(r"## Unreleased\n.*?(?=^## |\Z)", f"## Unreleased\n\n## {version} ({time.strftime('%Y-%m-%d')})\n" + "".join(f"- {n}\n" for n in notes) + "\n", s, count=1, flags=re.M | re.S)
    cl.write_text(s)
    return notes


def cmd_show(game: Path):
    d = load(game)
    print(f"in development: {d['version']} (build {d['build']})")
    for store in ("play", "apple"):
        s = d["stores"].get(store)
        print(f"  {store:5} " + (f"{s['version']} (build {s['build']}) {s['state']}" + (f" [{s['track']}]" if s.get('track') else "") + f"  updated {s['updated']}" if s else "nothing recorded"))
    behind = behind_stores(d)
    if behind:
        print("not live in: " + ", ".join(behind))


def behind_stores(d: dict) -> list:
    """Stores where the current version is not live (never submitted, still in review/testing, or an older version is live)."""
    out = []
    for store in ("play", "apple"):
        s = d["stores"].get(store)
        if not s or s["version"] != d["version"] or s["state"] != "live":
            out.append(store)
    return out


def main(argv):
    if len(argv) < 3 or argv[1] not in {"show", "note", "bump", "store"}:
        sys.exit(__doc__)
    cmd, game = argv[1], Path(argv[2]).resolve()
    d = load(game)
    if cmd == "show":
        return cmd_show(game)
    if cmd == "note":
        changelog_note(game, " ".join(argv[3:]))
        return print("noted")
    if cmd == "bump":
        part = argv[3] if len(argv) > 3 else ""
        if part not in {"major", "minor", "patch"}:
            sys.exit("bump needs major, minor or patch")
        d["version"], d["build"] = bump_version(d["version"], part), d["build"] + 1
        write_presets(game, d["version"], d["build"])
        notes = changelog_release(game, d["version"])
        d["history"].append({"version": d["version"], "build": d["build"], "date": time.strftime("%Y-%m-%d"), "notes": notes})
        save(game, d)
        print(f"now {d['version']} (build {d['build']}), written to export_presets.cfg and CHANGELOG.md")
        print("next: update whats_new in store/listing.json for every locale, rebuild (android_release.sh / ios_release.sh), then record each upload with `release.py store`")
        return
    if cmd == "store":
        store, state = argv[3], argv[4]
        if store not in {"play", "apple"} or state not in STATES:
            sys.exit(f"store must be play|apple, state one of {sorted(STATES)}")
        opt = {argv[i]: argv[i + 1] for i in range(5, len(argv) - 1, 2)}
        d["stores"][store] = {"version": opt.get("--version", d["version"]), "build": int(opt.get("--build", d["build"])),
                              "state": state, "track": opt.get("--track", ""), "updated": time.strftime("%Y-%m-%d")}
        save(game, d)
        return cmd_show(game)


if __name__ == "__main__":
    main(sys.argv)
