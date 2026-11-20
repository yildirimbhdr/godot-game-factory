#!/usr/bin/env python3
"""make_metadata.py <game-dir> <out-dir> [--notes-en TXT --notes-tr TXT --code N]
Turns <game>/store (listing.json + out/) into a fastlane supply metadata folder (en-US + tr-TR)."""
import json, shutil, sys, argparse
from pathlib import Path

ap = argparse.ArgumentParser()
ap.add_argument("game"); ap.add_argument("out")
ap.add_argument("--notes-en"); ap.add_argument("--notes-tr"); ap.add_argument("--code")
ap.add_argument("--no-listing", action="store_true", help="only changelogs (update runs)")
a = ap.parse_args()
store = Path(a.game) / "store"
listing = json.load(open(store / "listing.json", encoding="utf-8"))
out = Path(a.out)
shutil.rmtree(out, ignore_errors=True)
LOC = {"en": "en-US", "tr": "tr-TR"}
for k, loc in LOC.items():
    d = out / loc
    d.mkdir(parents=True)
    L = listing[k]
    if not a.no_listing:
        (d / "title.txt").write_text(L["title"], encoding="utf-8")
        (d / "short_description.txt").write_text(L["short"], encoding="utf-8")
        (d / "full_description.txt").write_text(L["full"], encoding="utf-8")
        o = store / "out"
        shots = sorted((o / "play" / k / "phone").glob("*.png"))
        if shots:
            (d / "images" / "phoneScreenshots").mkdir(parents=True)
            for i, s in enumerate(shots, 1):
                shutil.copy(s, d / "images" / "phoneScreenshots" / f"{i}.png")
        feat = o / ("play_feature_1024x500.png" if k == "en" else "play_feature_1024x500_tr.png")
        if feat.exists():
            (d / "images").mkdir(exist_ok=True)
            shutil.copy(feat, d / "images" / "featureGraphic.png")
        icon = o / "icons" / "play_512.png"
        if icon.exists():
            (d / "images").mkdir(exist_ok=True)
            shutil.copy(icon, d / "images" / "icon.png")
    notes = a.notes_en if k == "en" else a.notes_tr
    notes = notes or L.get("whats_new")
    if a.code and notes:
        (d / "changelogs").mkdir()
        (d / "changelogs" / f"{a.code}.txt").write_text(notes[:500], encoding="utf-8")
print("metadata ready:", out)
