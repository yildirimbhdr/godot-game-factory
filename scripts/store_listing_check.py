#!/usr/bin/env python3
"""Check <game>/store/listing.json against the stores' text limits (official pages, checked 2026-10-21).

  store_listing_check.py <game>

Per locale: Google Play title <=30, short description <=80, full description <=4000;
App Store name <=30, subtitle <=30, promotional text <=170, description <=4000, keywords <=100 bytes
(keywords must not repeat the name; each longer than 2 characters), What's New <=4000.
Exit 1 on any violation.
"""
import json, sys
from pathlib import Path

LIMITS = {"title": 30, "subtitle": 30, "short": 80, "promo": 170, "full": 4000, "whats_new": 4000}


def check(listing: dict) -> list[str]:
    bad = []
    for loc, t in listing.items():
        for key, limit in LIMITS.items():
            n = len(t.get(key, ""))
            if n > limit:
                bad.append(f"{loc}.{key}: {n} > {limit}")
            if not t.get(key) and key != "whats_new":
                bad.append(f"{loc}.{key}: missing")
        kb = len(t.get("keywords", "").encode("utf-8"))
        if kb > 100:
            bad.append(f"{loc}.keywords: {kb} bytes > 100")
        words = [w for w in t.get("keywords", "").split(",") if w]
        if any(len(w) <= 2 for w in words):
            bad.append(f"{loc}.keywords: every keyword must be longer than 2 characters")
        name_words = {w.lower() for w in t.get("title", "").replace(":", " ").split()}
        if any(w.lower() in name_words for w in words):
            bad.append(f"{loc}.keywords: repeats a word of the title")
    return bad


if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    data = json.loads((Path(sys.argv[1]) / "store" / "listing.json").read_text())
    problems = check(data)
    for loc, t in data.items():
        print(f"{loc}: title {len(t['title'])}/30, subtitle {len(t['subtitle'])}/30, short {len(t['short'])}/80, "
              f"promo {len(t['promo'])}/170, full {len(t['full'])}/4000, keywords {len(t['keywords'].encode())}/100 bytes")
    print("\n".join(problems) if problems else "listing OK")
    sys.exit(1 if problems else 0)
