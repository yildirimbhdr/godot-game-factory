#!/usr/bin/env python3
"""The user's own publisher profile, asked once and reused by every game: ~/.game-factory/profile.json

  gf_profile.py show                 print it
  gf_profile.py set <key> <value>    change one field (value is JSON if it parses, else text)
  gf_profile.py path

Keys: developer_name, brand, public_contact_email, default_locales, workspace, firebase_project,
      android_keystore, android_keychain_service, website, support_url, hosting_site (a Firebase Hosting site id that is NOT a project's default site).
It stays on this machine. It holds no passwords (those live in the macOS Keychain) and the plugin never sends it anywhere.
Only put a PUBLIC contact email here: it is printed into privacy policies and store listings.
"""
import json, sys
from pathlib import Path

PATH = Path.home() / ".game-factory" / "profile.json"
DEFAULTS = {"developer_name": "", "brand": "", "public_contact_email": "", "default_locales": ["en"], "workspace": "",
            "firebase_project": "", "android_keystore": "", "android_keychain_service": "game-factory-android-upload",
            "website": "", "support_url": "", "hosting_site": ""}


def load() -> dict:
    data = dict(DEFAULTS)
    if PATH.is_file():
        data.update(json.loads(PATH.read_text()))
    return data


def save(data: dict) -> None:
    PATH.parent.mkdir(parents=True, exist_ok=True)
    PATH.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n")
    PATH.chmod(0o600)


def publisher_line(p: dict) -> str:
    """Name shown to users in policies: 'brand (developer)' or whichever exists."""
    if p["brand"] and p["developer_name"]:
        return f"{p['brand']} ({p['developer_name']})"
    return p["brand"] or p["developer_name"]


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    if cmd == "show":
        print(json.dumps(load(), ensure_ascii=False, indent=2))
    elif cmd == "path":
        print(PATH)
    elif cmd == "set" and len(sys.argv) == 4:
        d = load()
        if sys.argv[2] not in DEFAULTS:
            sys.exit(f"unknown key {sys.argv[2]}; keys: {', '.join(DEFAULTS)}")
        try:
            d[sys.argv[2]] = json.loads(sys.argv[3])
        except json.JSONDecodeError:
            d[sys.argv[2]] = sys.argv[3]
        save(d)
        print("saved", sys.argv[2])
    else:
        sys.exit(__doc__)
