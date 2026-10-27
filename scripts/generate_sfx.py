#!/usr/bin/env python3
"""Build game sound effects from a small JSON spec. Run through scripts/sfx.sh.

Spec (assets/audio/sfx.spec.json), one entry per sound name; two sources:
  {"ui_click": {"source": "kenney", "pack": "interface-sounds", "file": "Audio/click_001.ogg"},
   "score":    {"source": "pyfxr", "preset": "pickup", "seed": 7}}
`source` defaults to "pyfxr" (retro synth, presets: pickup laser explosion powerup hurt jump select).
Kenney packs are CC0 and are downloaded once into the cache (see kenney.py).
Optional per entry: "gain" (1.0 = default level).

  generate_sfx.py build    <project> [--only NAME]   write assets/audio/sfx/<name>.wav
  generate_sfx.py audition <project> NAME [--count N] pyfxr only: N seed variants in assets/audio/audition/
Every build also writes assets/audio/sfx.lock.json and refreshes the generated block in ASSETS.md.
"""
import argparse, datetime, json, random, struct, subprocess, sys, wave
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import kenney

RATE = 44100
PEAK = 0.5          # about -6 dBFS; leaves headroom when sounds overlap
FADE_MS = 8         # avoids a click at the end of the sample
MARK_BEGIN, MARK_END = "<!-- generated-sfx:begin -->", "<!-- generated-sfx:end -->"
PYFXR_PRESETS = ("pickup", "laser", "explosion", "powerup", "hurt", "jump", "select")


def render_pyfxr(preset, seed):
    import pyfxr
    random.seed(seed)
    sfx = getattr(pyfxr, preset)()
    return list(memoryview(sfx.build())), sfx.as_dict()


def render_kenney(pack, file):
    path = kenney.fetch(pack) / file
    if not path.is_file():
        raise FileNotFoundError(f"{file} not in pack {pack}")
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", str(path), "-f", "s16le", "-ac", "1", "-ar", str(RATE), "-"],
                         check=True, capture_output=True).stdout
    return list(struct.unpack("<%dh" % (len(raw) // 2), raw))


def process(samples, gain):
    peak = max((abs(s) for s in samples), default=0)
    if peak == 0:
        raise ValueError("sound is silent")
    scale = PEAK * 32767 * gain / peak
    out = [max(-32767, min(32767, int(s * scale))) for s in samples]
    fade = min(len(out), int(RATE * FADE_MS / 1000))
    for i in range(fade):
        out[-1 - i] = int(out[-1 - i] * (i / fade))
    return out


def write_wav(path, samples):
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(struct.pack("<%dh" % len(samples), *samples))


def build(project, only):
    audio = project / "assets" / "audio"
    spec = json.loads((audio / "sfx.spec.json").read_text())
    lock_path = audio / "sfx.lock.json"
    old = json.loads(lock_path.read_text()) if lock_path.exists() else {}
    lock = {}
    for name, e in spec.items():
        if only and name != only:
            lock[name] = old.get(name)
            if lock[name] is None:
                del lock[name]
            continue
        source = e.get("source", "pyfxr")
        record = {"source": source, "gain": e.get("gain", 1.0)}
        if source == "kenney":
            samples = render_kenney(e["pack"], e["file"])
            record.update(pack=e["pack"], file=e["file"], license="CC0")
        elif source == "pyfxr":
            if e["preset"] not in PYFXR_PRESETS:
                raise ValueError(f"{name}: unknown preset {e['preset']}")
            samples, params = render_pyfxr(e["preset"], e["seed"])
            record.update(preset=e["preset"], seed=e["seed"], params=params, license="CC0")
        else:
            raise ValueError(f"{name}: unknown source {source}")
        out = process(samples, record["gain"])
        write_wav(audio / "sfx" / f"{name}.wav", out)
        record["seconds"] = round(len(out) / RATE, 3)
        record["date"] = old.get(name, {}).get("date", datetime.date.today().isoformat())
        lock[name] = record
        print(f"{name}: {source} {e.get('file') or e['preset']} {record['seconds']}s")
    lock_path.write_text(json.dumps(lock, indent=2, sort_keys=True) + "\n")
    update_assets_md(project, lock)


def update_assets_md(project, lock):
    rows = []
    for n, e in sorted(lock.items()):
        if e["source"] == "kenney":
            src = f"https://kenney.nl/assets/{e['pack']}"
            author, note = "Kenney", f"{e['file']}, level-normalized"
        else:
            import importlib.metadata as md
            src = f"generated: pyfxr {md.version('pyfxr')}, preset {e['preset']}, seed {e['seed']}"
            author, note = "game-factory-godot", "parameters in assets/audio/sfx.lock.json"
        rows.append(f"| assets/audio/sfx/{n}.wav | sfx | {src} | {author} | CC0 | {e['date']} | {note} |")
    block = f"{MARK_BEGIN}\n" + "\n".join(rows) + f"\n{MARK_END}"
    path = project / "ASSETS.md"
    text = path.read_text() if path.exists() else "# Assets\n\n| File(s) | Type | Source URL | Author | License | Date added | Notes |\n|---|---|---|---|---|---|---|\n"
    if MARK_BEGIN in text:
        head, rest = text.split(MARK_BEGIN, 1)
        text = head + block + rest.split(MARK_END, 1)[1]
    else:
        text = text.rstrip("\n") + "\n" + block + "\n"
    path.write_text(text)


def audition(project, name, count):
    spec = json.loads((project / "assets" / "audio" / "sfx.spec.json").read_text())
    e = spec[name]
    if e.get("source", "pyfxr") != "pyfxr":
        sys.exit("audition only supports pyfxr entries")
    for seed in range(1, count + 1):
        samples, _ = render_pyfxr(e["preset"], seed)
        write_wav(project / "assets" / "audio" / "audition" / f"{name}_seed{seed}.wav", process(samples, e.get("gain", 1.0)))
    print(f"wrote {count} candidates for {name} to assets/audio/audition/")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    b = sub.add_parser("build"); b.add_argument("project"); b.add_argument("--only")
    a = sub.add_parser("audition"); a.add_argument("project"); a.add_argument("name"); a.add_argument("--count", type=int, default=8)
    args = ap.parse_args()
    project = Path(args.project).resolve()
    build(project, args.only) if args.cmd == "build" else audition(project, args.name, args.count)


if __name__ == "__main__":
    sys.exit(main())
