#!/usr/bin/env python3
"""Download and cache Kenney asset packs (https://kenney.nl/assets), only if the page states CC0.

  kenney.py fetch <slug>    print the local path of the unpacked pack (downloads on first use)
Cache: $GAME_FACTORY_CACHE/kenney/<slug> (default ~/.cache/game-factory-godot/kenney/<slug>)
"""
import os, re, sys, urllib.request, zipfile
from pathlib import Path

CACHE = Path(os.environ.get("GAME_FACTORY_CACHE", Path.home() / ".cache" / "game-factory-godot")) / "kenney"
LINK = re.compile(r"https://kenney\.nl/media/pages/assets/[^\"' ]+\.zip")


def fetch(slug: str) -> Path:
    if not re.fullmatch(r"[a-z0-9-]+", slug):
        raise ValueError(f"bad pack slug: {slug}")
    dest = CACHE / slug
    if dest.exists() and any(dest.iterdir()):
        return dest
    page = f"https://kenney.nl/assets/{slug}"
    html = urllib.request.urlopen(page, timeout=30).read().decode("utf-8", "replace")
    if "Creative Commons CC0" not in html:
        raise RuntimeError(f"{page} does not state CC0; not downloading")
    match = LINK.search(html)
    if not match:
        raise RuntimeError(f"no download link found on {page}")
    CACHE.mkdir(parents=True, exist_ok=True)
    archive = CACHE / f"{slug}.zip"
    urllib.request.urlretrieve(match.group(0), archive)
    dest.mkdir(parents=True)
    with zipfile.ZipFile(archive) as z:
        for name in z.namelist():           # untrusted archive: refuse paths that escape the folder
            target = (dest / name).resolve()
            if dest.resolve() not in target.parents and target != dest.resolve():
                raise RuntimeError(f"unsafe path in archive: {name}")
        z.extractall(dest)
    archive.unlink()
    return dest


if __name__ == "__main__":
    if len(sys.argv) != 3 or sys.argv[1] != "fetch":
        sys.exit(__doc__)
    print(fetch(sys.argv[2]))
