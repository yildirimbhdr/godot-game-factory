#!/usr/bin/env python3
"""Fill the App Store Connect fields that block "Add for Review", through the API key (no browser).

  app_setup.py apply <game>      content rights, categories, age rating questionnaire, free price (from the brief and the project)
  app_setup.py check <game>      read-only: what is still missing (content rights, category, age rating, price, build, screenshots, contact, notes)

Not possible through the API (Apple offers no endpoint for it): App Privacy (the privacy label). store/declarations.html has the answers.
The age rating follows store_declarations.py (ads detected -> advertising yes; brief "violence": none|cartoon|realistic). These are the owner's
legal declarations: read the proposal in store/declarations.html first. Ticks the matching steps in store/status.json.
"""
import json, os, re, shutil, subprocess, sys, tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import gf_status, store_declarations  # noqa: E402

GENRE = {"puzzle": "GAMES_PUZZLE", "action": "GAMES_ACTION", "arcade": "GAMES_ARCADE", "casual": "GAMES_CASUAL", "adventure": "GAMES_ADVENTURE",
         "strategy": "GAMES_STRATEGY", "card": "GAMES_CARD", "board": "GAMES_BOARD", "word": "GAMES_WORD", "simulation": "GAMES_SIMULATION",
         "role playing": "GAMES_ROLE_PLAYING", "racing": "GAMES_RACING", "sports": "GAMES_SPORTS", "trivia": "GAMES_TRIVIA", "music": "GAMES_MUSIC"}
LEVEL = ["alcohol_tobacco_or_drug_use_or_references", "contests", "gambling_simulated", "guns_or_other_weapons", "horror_or_fear_themes",
         "mature_or_suggestive_themes", "medical_or_treatment_information", "profanity_or_crude_humor", "sexual_content_graphic_and_nudity",
         "sexual_content_or_nudity", "violence_cartoon_or_fantasy", "violence_realistic_prolonged_graphic_or_sadistic", "violence_realistic"]
FLAGS = ["gambling", "loot_box", "messaging_and_chat", "parental_controls", "social_media", "unrestricted_web_access",
         "user_generated_content", "health_or_wellness_topics", "age_assurance"]


def build_config(game: Path) -> dict:
    brief = store_declarations.read_brief(game)
    f = store_declarations.detect(game)
    violence = str(brief.get("violence", "none"))
    genre = str(brief.get("genre", "puzzle")).lower()
    sub1 = GENRE.get(genre, "GAMES_PUZZLE")
    sub2 = "GAMES_CASUAL" if sub1 != "GAMES_CASUAL" else "GAMES_ARCADE"
    age = {k: "NONE" for k in LEVEL}
    age.update({k: False for k in FLAGS})
    age["advertising"] = bool(f["ads"])
    if violence == "cartoon":
        age["violence_cartoon_or_fantasy"] = "INFREQUENT_OR_MILD"
    elif violence == "realistic":
        age["violence_realistic"] = "INFREQUENT_OR_MILD"
    return {"content_rights": "USES_THIRD_PARTY_CONTENT",   # CC0 / OFL sounds and fonts count as third-party content, rights held
            "categories": {"primary_category_id": "GAMES", "primary_subcategory_one_id": sub1, "primary_subcategory_two_id": sub2},
            "age_rating": age, "free": not f["iap"]}


def run_lane(game: Path, lane: str, extra: dict) -> list:
    st = gf_status.load(game)
    env = gf_status._fastlane_env()
    env.update(GF_BUNDLE=st["bundle_id"], **extra)
    with tempfile.TemporaryDirectory() as tmp:
        (Path(tmp) / "fastlane").mkdir()
        shutil.copy(HERE.parent / "templates" / "fastlane" / "Fastfile.probe", Path(tmp) / "fastlane" / "Fastfile")
        r = subprocess.run(["fastlane", "ios", lane], cwd=tmp, env=env, capture_output=True, text=True, timeout=300)
    lines = [re.sub(r"^.*?GF_ASC ", "", l) for l in (r.stdout + r.stderr).splitlines() if "GF_ASC" in l or "[!]" in l]
    if r.returncode != 0 and not any(l.startswith("[!]") for l in lines):
        lines.append("[!] " + (r.stderr or r.stdout).strip().splitlines()[-1][:300])
    return lines


def apply(game: Path) -> int:
    lines = run_lane(game, "app_setup", {"GF_SETUP_JSON": json.dumps(build_config(game))})
    print("\n".join(lines))
    if any(l.startswith("[!]") for l in lines):
        return 1
    gf_status.init(game)
    d = gf_status.load(game)
    for m in d["manual"]:
        if m["id"] in ("apple.category", "apple.content_rights", "apple.age_rating", "apple.pricing"):
            m["done"], m["done_on"] = True, gf_status.today() + " (set through the API)"
    gf_status.save(game, d)
    return 0


def check(game: Path) -> int:
    lines = run_lane(game, "readiness", {})
    ready = {m.group(1): m.group(2) == "true" for l in lines for m in [re.match(r"ready (\w+)=(true|false)", l)] if m}
    for k, v in ready.items():
        print(("  OK    " if v else "  OPEN  ") + k)
    print("  OPEN  app_privacy (no API: App Store Connect > App Privacy; answers in store/declarations.html)")
    missing = [k for k, v in ready.items() if not v]
    return 1 if missing or not ready else 0


if __name__ == "__main__":
    if len(sys.argv) < 3 or sys.argv[1] not in {"apply", "check"}:
        sys.exit(__doc__)
    g = Path(sys.argv[2]).resolve()
    sys.exit(apply(g) if sys.argv[1] == "apply" else check(g))
