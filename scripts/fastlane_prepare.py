#!/usr/bin/env python3
"""Turn a game's store package into a fastlane project, so the stores are filled by one command and no Claude tokens.

  fastlane_prepare.py <game> [--first]

Reads  <game>/store/listing.json   (texts per locale: title, subtitle, short, promo, keywords, full, whats_new)
       <game>/store/status.json    (privacy_url, support_url)
       <game>/store/out/           (icons, apple/<locale>/iphone_6.3|6.9/NN.png, play/<locale>/phone/NN.png, play_feature_1024x500.png)
       <game>/export_presets.cfg   (bundle id, package name, version)
Writes <game>/fastlane/  Appfile, Fastfile, metadata/ (iOS), metadata/android/ (Play), screenshots/ (iOS)

--first   first release of the app: no "What's New" for iOS (Apple refuses it for version 1.0), no changelog for Play.

Then (see skills/store-release/playbooks/fastlane.md):
  cd <game> && fastlane ios metadata      # texts + screenshots to App Store Connect (does not submit)
  cd <game> && fastlane ios build_upload  # signed build to App Store Connect (TestFlight)
  cd <game> && fastlane android listing   # texts + images to Play Console
  cd <game> && fastlane android release   # AAB to the chosen track as a draft
Nothing is submitted for review by these lanes; the final submit stays a deliberate human click (or add `submit_for_review: true`).
"""
import json, re, shutil, sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
FASTFILE_VERSION = 4

APPLE_LOCALE = {"en": "en-US", "tr": "tr", "de": "de-DE", "fr": "fr-FR", "es": "es-ES", "pt": "pt-BR", "it": "it", "ja": "ja", "ko": "ko",
                "ru": "ru", "ar": "ar-SA", "nl": "nl-NL", "pl": "pl", "id": "id", "zh": "zh-Hans"}
PLAY_LOCALE = {"en": "en-US", "tr": "tr-TR", "de": "de-DE", "fr": "fr-FR", "es": "es-ES", "pt": "pt-BR", "it": "it-IT", "ja": "ja-JP",
               "ko": "ko-KR", "ru": "ru-RU", "ar": "ar", "nl": "nl-NL", "pl": "pl-PL", "id": "id", "zh": "zh-CN"}


def w(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text.rstrip("\n") + "\n", encoding="utf-8")


def preset_value(cfg: str, key: str, default=""):
    m = re.search(r'^' + re.escape(key) + r'="?([^"\n]*)"?', cfg, re.M)
    return m.group(1) if m else default


def main(game: Path, first: bool) -> None:
    store = game / "store"
    listing = json.loads((store / "listing.json").read_text())
    status = json.loads((store / "status.json").read_text()) if (store / "status.json").is_file() else {}
    presets = (game / "export_presets.cfg").read_text()
    bundle = preset_value(presets, "application/bundle_identifier")
    package = preset_value(presets, "package/unique_name", bundle)
    fl = game / "fastlane"
    if fl.exists():
        shutil.rmtree(fl / "metadata", ignore_errors=True)
        shutil.rmtree(fl / "screenshots", ignore_errors=True)
    out = store / "out"

    for loc, t in listing.items():
        a = fl / "metadata" / APPLE_LOCALE.get(loc, loc)
        w(a / "name.txt", t["title"])
        w(a / "subtitle.txt", t["subtitle"])
        w(a / "description.txt", t["full"])
        w(a / "keywords.txt", t["keywords"])
        w(a / "promotional_text.txt", t["promo"])
        if status.get("support_url"):
            w(a / "support_url.txt", status["support_url"])
        if status.get("privacy_url"):
            w(a / "privacy_url.txt", status["privacy_url"])
        if not first and t.get("whats_new"):
            w(a / "release_notes.txt", t["whats_new"])
        shots = out / "apple" / loc / "iphone_6.9"
        if shots.is_dir():   # deliver sorts by pixel size, so both 6.9" and 6.3" sets can sit in one folder
            for i, f in enumerate(sorted(shots.glob("*.png")), 1):
                dest = fl / "screenshots" / APPLE_LOCALE.get(loc, loc) / f"{i:02d}_69.png"
                dest.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy(f, dest)
        shots = out / "apple" / loc / "iphone_6.3"
        if shots.is_dir():
            for i, f in enumerate(sorted(shots.glob("*.png")), 1):
                dest = fl / "screenshots" / APPLE_LOCALE.get(loc, loc) / f"{i:02d}_63.png"
                dest.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy(f, dest)

        p = fl / "metadata" / "android" / PLAY_LOCALE.get(loc, loc)
        w(p / "title.txt", t["title"])
        w(p / "short_description.txt", t["short"])
        w(p / "full_description.txt", t["full"])
        pics = out / "play" / loc / "phone"
        for i, f in enumerate(sorted(pics.glob("*.png")), 1) if pics.is_dir() else []:
            (p / "images" / "phoneScreenshots").mkdir(parents=True, exist_ok=True)
            shutil.copy(f, p / "images" / "phoneScreenshots" / f"{i}.png")
        for src, name in ((out / "icons" / "play_512.png", "icon.png"), (out / "play_feature_1024x500.png", "featureGraphic.png")):
            if src.is_file():
                (p / "images").mkdir(parents=True, exist_ok=True)
                shutil.copy(src, p / "images" / name)

    import time, gf_profile
    owner = (gf_profile.load().get("developer_name") or "").strip()
    if owner:   # App Store Connect wants a copyright line; precheck fails without a current year
        w(fl / "metadata" / "copyright.txt", f"{time.strftime('%Y')} {owner}")

    import review_notes   # Apple rejects apps without review notes + a screen recording link: notes, contact and phone go with the metadata
    review_notes.write_deliver_files(game, fl / "metadata")

    w(fl / "Appfile", f'''# Generated by fastlane_prepare.py. Secrets are NOT here: paths come from the environment (see playbooks/fastlane.md).
app_identifier("{bundle}")
package_name("{package}")
json_key_file(ENV["GF_PLAY_JSON_KEY"]) if ENV["GF_PLAY_JSON_KEY"]
''')
    import store_declarations
    ads = store_declarations.detect(game)["ads"]
    idfa = ("add_id_info_uses_idfa: true, add_id_info_serves_ads: true, add_id_info_tracks_install: false, "
            "add_id_info_tracks_action: false, add_id_info_limits_tracking: true") if ads else "add_id_info_uses_idfa: false"
    fastfile = (HERE.parent / "templates" / "fastlane" / "Fastfile.tmpl").read_text()
    for k, v in (("__VERSION__", str(FASTFILE_VERSION)), ("__BUNDLE__", bundle), ("__PACKAGE__", package), ("__IDFA__", idfa)):
        fastfile = fastfile.replace(k, v)
    ff = fl / "Fastfile"
    old = ff.read_text() if ff.is_file() else ""
    if f"fastfile-version: {FASTFILE_VERSION})" in old:
        print("Fastfile is current, left alone")
    else:
        if old:
            shutil.copy(ff, fl / "Fastfile.bak")
            print("old Fastfile kept as Fastfile.bak")
        w(ff, fastfile)

    print(f"fastlane project written to {fl} (bundle {bundle}, package {package}, first={first})")
    langs = ", ".join(sorted(listing))
    print(f"locales: {langs}; check with: cd {game.name} && fastlane lanes")


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    if not args:
        sys.exit(__doc__)
    main(Path(args[0]).resolve(), "--first" in sys.argv)
