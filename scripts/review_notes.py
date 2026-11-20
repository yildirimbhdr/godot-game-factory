#!/usr/bin/env python3
"""App Store review notes (Apple now rejects apps that come without them: "We need additional information to better understand the app").

  review_notes.py generate <game>        write <game>/store/review_notes.txt from the brief, the listing and what the project contains
  review_notes.py apply <game>           send the notes + review contact to the game's editable App Store Connect version (no submission)
  review_notes.py check <game>           exit 1 if the recording link is missing

Apple's requirements (all go into the Notes field of App Review Information):
  1 a screen recording on a physical device, latest iOS, from launch through the typical flow (account flows, user content, paid content if any)
  2 purpose and target audience       3 how to reach the main features (login, sample files)
  4 external services the app uses    5 regional differences or "consistent in all regions"
  6 documentation for regulated industries or protected third-party material
Items 2-6 are generated. Item 1 cannot be: record the screen on the phone (Control Center > Screen Recording), put the video on a link anyone
can open (YouTube unlisted, Drive "anyone with the link") and save that URL in <game>/store/review_video_url.txt.
The review contact (name, email from the profile; phone from the profile key review_phone) is sent together with the notes.
"""
import json, os, re, shutil, subprocess, sys, tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import gf_profile, store_declarations  # noqa: E402


def video_url(game: Path) -> str:
    p = game / "store" / "review_video_url.txt"
    return p.read_text().strip() if p.is_file() else ""


def build_text(game: Path) -> str:
    brief = store_declarations.read_brief(game)
    f = store_declarations.detect(game)
    try:
        listing = json.loads((game / "store" / "listing.json").read_text())
    except Exception:
        listing = {}
    en = listing.get("en", {})
    name = brief.get("title") or en.get("title") or game.name
    purpose = brief.get("idea") or (en.get("full", "").split("\n\n")[0] if en.get("full") else "") or en.get("short", "")
    loop = brief.get("core_loop", "")
    audience = "casual players aged 13 and over who like short puzzle sessions; not directed at children"
    url = video_url(game)
    art_src = str((brief.get("art") or {}).get("source", "")).lower()
    art_line = ("The artwork was created by the developer with AI image tools before release (nothing is generated while the app runs); sounds and fonts are open (CC0 / OFL) licensed and listed in the project's ASSETS file."
                if any(k in art_src for k in ("gemini", "pixellab", "ai", "generat")) else
                "Artwork, sounds and fonts are the developer's own or open (CC0 / OFL) licensed and listed in the project's ASSETS file.")
    services = []
    if f["ads"]:
        services += ["Google AdMob: banner-free full-screen ads. A rewarded video is shown only when the player taps a button to get a hint, extra life or similar; interstitials appear between levels, never during play.",
                     "Google User Messaging Platform: the consent form that is shown in the EEA/UK before any ad is requested."]
    if f["analytics"]:
        services.append("Firebase Analytics (Google): anonymous usage events such as level start and level end, collected only after consent is known.")
    if f["iap"]:
        services.append("Apple In-App Purchase for the paid items.")
    if not services:
        services.append("None. The app works fully offline and talks to no server.")
    services.append("No accounts, no sign-in service" + ("" if f["iap"] else ", no payment processor") + " and no AI service is used while the app runs; everything runs on the device.")
    regional = ("The app works the same in every region. The only difference: in the EEA and UK a consent form is shown on first launch and a "
                "\"Privacy options\" button appears in Settings. " if f["ads"] else "The app works the same in every region. ")
    regional += "Languages: " + (", ".join({"en": "English", "tr": "Turkish"}.get(k, k) for k in listing) or "English") + " (chosen from the device language, changeable in Settings)."
    lines = [
        ("Screen recording (physical iPhone, latest iOS, from app launch through the typical flow): " + url) if url else
        "Screen recording (physical iPhone, latest iOS): LINK MISSING - add it to store/review_video_url.txt and run review_notes.py apply",
        "",
        "Purpose and audience",
        f"{name}: {purpose}".strip() + (f" {loop}" if loop else ""),
        f"Target audience: {audience}.",
        "",
        "How to use the app",
        "No account, login, sample files or purchases are needed. Launch the app and tap Play. A short guided tutorial may start first; "
        "after it the levels are played in order from the level map. Progress is saved on the device. Settings (gear icon) has sound, vibration and language.",
        "",
        "External services",
        *[f"- {s}" for s in services],
        "",
        "Regional differences",
        regional,
        "",
        "Regulated industry and protected material",
        "Not applicable. The app is not in a regulated industry and contains no protected third-party material. " + art_line,
    ]
    return "\n".join(lines) + "\n"


def generate(game: Path) -> Path:
    out = game / "store" / "review_notes.txt"
    out.parent.mkdir(exist_ok=True)
    out.write_text(build_text(game), encoding="utf-8")
    return out


def contact() -> dict:
    prof = gf_profile.load()
    name = (prof.get("developer_name") or "").strip().split()
    return {"first": name[0] if name else "", "last": " ".join(name[1:]) if len(name) > 1 else "",
            "email": prof.get("public_contact_email", ""), "phone": prof.get("review_phone", "")}


def write_deliver_files(game: Path, meta_dir: Path) -> None:
    """For deliver (fastlane metadata/review_information): used by fastlane_prepare.py."""
    d = meta_dir / "review_information"
    d.mkdir(parents=True, exist_ok=True)
    notes = generate(game)
    (d / "notes.txt").unlink(missing_ok=True)
    if video_url(game):   # never send notes that still say "LINK MISSING"
        shutil.copy(notes, d / "notes.txt")
    c = contact()
    for fn in ("first_name.txt", "last_name.txt", "email_address.txt", "phone_number.txt"):
        (d / fn).unlink(missing_ok=True)
    if c["phone"]:   # the API refuses contact changes without a phone number ("You must provide a value for the attribute contactPhone")
        for fn, k in (("first_name.txt", "first"), ("last_name.txt", "last"), ("email_address.txt", "email"), ("phone_number.txt", "phone")):
            if c[k]:
                (d / fn).write_text(c[k], encoding="utf-8")


def apply(game: Path) -> int:
    notes = generate(game)
    if not video_url(game):
        print("The screen recording link is missing: Apple will reject the notes without it.\n"
              f"Record the app on the phone, host the video, save the link in {game / 'store' / 'review_video_url.txt'} and run this again.")
        return 1
    bundle = (game / "bundle_id.txt").read_text().strip() if (game / "bundle_id.txt").is_file() else ""
    if not bundle:
        import gf_status
        bundle = gf_status.load(game)["bundle_id"]
    env = dict(os.environ)
    envf = Path.home() / ".game-factory" / "fastlane.env"
    for line in envf.read_text().splitlines() if envf.is_file() else []:
        m = re.match(r'\s*export\s+(\w+)=(?:"([^"]*)"|(\S*))', line)
        if m:
            env[m.group(1)] = (m.group(2) if m.group(2) is not None else m.group(3)).replace("$HOME", str(Path.home()))
    c = contact()
    env.update(GF_BUNDLE=bundle, GF_NOTES_FILE=str(notes), GF_CONTACT_FIRST=c["first"], GF_CONTACT_LAST=c["last"],
               GF_CONTACT_EMAIL=c["email"], GF_CONTACT_PHONE=c["phone"], FASTLANE_SKIP_UPDATE_CHECK="1")
    with tempfile.TemporaryDirectory() as tmp:
        (Path(tmp) / "fastlane").mkdir()
        shutil.copy(HERE.parent / "templates" / "fastlane" / "Fastfile.probe", Path(tmp) / "fastlane" / "Fastfile")
        r = subprocess.run(["fastlane", "ios", "review_info"], cwd=tmp, env=env, capture_output=True, text=True, timeout=180)
    out = [re.sub(r"^.*?GF_ASC ", "", l) for l in (r.stdout + r.stderr).splitlines() if "GF_ASC" in l or "[!]" in l]
    print("\n".join(out) or (r.stderr or r.stdout)[-400:])
    if not c["phone"]:
        print("Note: no review phone number is set (gf_profile.py set review_phone +90...). Enter it in App Store Connect before submitting.")
    return r.returncode


if __name__ == "__main__":
    if len(sys.argv) < 3 or sys.argv[1] not in {"generate", "apply", "check"}:
        sys.exit(__doc__)
    game = Path(sys.argv[2]).resolve()
    if sys.argv[1] == "generate":
        print("wrote", generate(game))
    elif sys.argv[1] == "check":
        ok = bool(video_url(game))
        print("recording link: " + (video_url(game) if ok else "MISSING"))
        sys.exit(0 if ok else 1)
    else:
        sys.exit(apply(game))
