#!/usr/bin/env python3
"""The answer sheet for the store forms that no API can fill (Apple age rating, privacy labels, Play content rating, data safety ...).

  store_declarations.py <game> [--violence none|cartoon|realistic] [--kids]

Reads what the game really contains (ads/analytics SDKs, purchases, network code, accounts) and the brief (brief.json:
monetization.ads/analytics/iap, audience, violence, art.source), and writes two files:
  <game>/store/declarations.html   ONE page: every form, the exact answer with a copy button, why, and a tick box
                                   (ticks are remembered in the browser; open it next to the store console)
  <game>/store/declarations.md     the same content as text
A flag on the command line wins over the brief, the brief wins over detection defaults.
It is a proposal for the owner, who gives these legal declarations; if the game changes (ads added, analytics added) run it again.
"""
import html, json, re, sys
from pathlib import Path


def read_brief(game: Path) -> dict:
    p = game / "brief.json"
    try:
        return json.loads(p.read_text()) if p.is_file() else {}
    except ValueError:
        return {}


def detect(game: Path) -> dict:
    def has(p): return (game / p).exists()
    gd = "\n".join(p.read_text(errors="ignore") for p in game.rglob("*.gd") if ".godot" not in p.parts and "addons" not in p.parts) if game.exists() else ""
    ads_script = (game / "autoload" / "ads.gd")
    mock_ads = ads_script.is_file() and "mock" in ads_script.read_text(errors="ignore").lower() and not has("addons/admob")
    mon = read_brief(game).get("monetization") or {}
    return {
        "ads": has("addons/admob") or (ads_script.is_file() and not mock_ads) or bool(mon.get("ads")),
        "analytics": has("addons/godotx_firebase") or bool(mon.get("analytics")),
        "iap": (bool(re.search(r"\b(purchase|billing|IAP|in_app)\b", gd, re.I)) and has("addons")) or bool(mon.get("iap")),
        "network": bool(re.search(r"HTTPRequest|WebSocket|ENet|MultiplayerPeer", gd)),
        "account": bool(re.search(r"\blogin\b|sign_in|signin", gd, re.I)),
    }


def build_sections(game: Path, violence: str, kids: bool) -> list:
    """[{title, rows:[{form, answer, why}]}] - the single source for the md and the html."""
    f = detect(game)
    brief = read_brief(game)
    ads, an, iap = f["ads"], f["analytics"], f["iap"]
    collects = ads or an
    gen_art = any(k in str((brief.get("art") or {}).get("source", "")).lower() for k in ("gemini", "pixellab", "ai", "generat"))
    try:
        import gf_status
        st = gf_status.load(game)
        privacy, support = st.get("privacy_url") or "(deploy the privacy page first)", st.get("support_url") or "(your support page)"
    except Exception:
        privacy, support = "(the privacy_url from store/status.json)", "(your support page)"

    def R(form, answer, why=""): return {"form": form, "answer": answer, "why": why}

    data_types_apple = ("Device ID + Advertising Data + Usage Data (AdMob), " if ads else "") + ("Product Interaction + Diagnostics (Firebase Analytics)" if an else "")
    sev = {"none": "None in every row", "cartoon": "Cartoon or Fantasy Violence = Infrequent, all other rows None (gives 9+)",
           "realistic": "Realistic Violence = Infrequent or Frequent according to the game (gives 12+ to 17+)"}[violence]
    apple = [
        R("App Privacy > Get Started (Data Collection)", ("Yes, we collect data. Then: " + data_types_apple) if collects else "No, we do not collect data. Publish.",
          "ads/analytics SDKs send data off the device" if collects else "no SDK sends anything off the device"),
        R("App Privacy > Privacy Policy URL", privacy, "enter it for EVERY localized language; Add for Review fails if one locale is missing"),
        R("App Information > Content Rights", "Yes, I have the necessary rights", "Kenney / OFL / generated assets count as third-party content; answer No only if every asset is your own"),
        R("App Information > Age Ratings (7 steps)", f"Features: all No{' except Advertising = Yes' if ads else ''}. Mature themes, medical, sexual: None. Violence: {sev}. Gambling/loot box: None/No",
          "the questionnaire is by content, not by audience"),
        R("Version page > App Review Information", "your name, phone with country code (+90...), email; untick Sign-in required unless the game has accounts", "the phone is required and blocks Save"),
        R("Pricing and Availability", "Free (US $0, all 175 countries), availability All Countries", "change later only if you add paid features"),
        R("App Privacy > each data type: tracking",
          "No, unless the game shows the App Tracking Transparency prompt (then Yes for Device ID and Advertising Data and add NSUserTrackingUsageDescription)" if ads else "n/a",
          "without the ATT prompt the IDFA is never delivered, so nothing is tracked"),
        R("Submit", f"Export compliance: standard HTTPS only = exempt. Advertising Identifier: {'Yes (AdMob) and serve ads' if ads else 'No'}", ""),
    ]
    iarc_violence = ("Violence: Yes > violence against non-humans/fantasy creatures, fantasy setting, pixelated, unrealistic reactions, rarely from afar, no blood. "
                     if violence == "cartoon" else "Violence: No. ")
    play = [
        R("Create app", "Game, Free, tick both declarations yourself", "legal declarations"),
        R("App content > Privacy policy", privacy, ""),
        R("App content > App access", "All functionality available without restrictions" + (" (test login needed: the game has accounts)" if f["account"] else ""), "no accounts" if not f["account"] else "give Google a test login"),
        R("App content > Ads", "Yes, contains ads" if ads else "No, no ads", ""),
        R("App content > Content rating (IARC)", "Category Game, your email, accept IARC terms. " + iarc_violence +
          "Fear, sex, gambling, language, drugs, crude humor, location sharing, user interaction: No. Purchases: " + ("Yes" if iap else "No"), "answer the same way as Apple"),
        R("App content > Target audience", "5 and under ... 12 (Families policy applies, ads limited)" if kids else "13-15, 16-17, 18+ (not for children)", "13+ avoids the Families Policy"),
        R("App content > Data safety",
          "Collected/shared: Device or other IDs, App interactions, Diagnostics (from AdMob/Firebase); encrypted in transit: yes; no account creation; users cannot request deletion (nothing account-based is stored)" if collects
          else "Does your app collect or share any required user data types? No. Preview shows Data not collected, no sharing", "must match Apple"),
        R("App content > Advertising ID", "Yes, used for advertising (and analytics)" if ads else "No", ""),
        R("App content > Government apps / Financial features / Health", "No / none of the features (tick the box at the bottom of the list) / none", ""),
        R("Store settings", f"Category: Puzzle for a puzzle game. Public email: yours. Website: {support}", "AdMob reads /app-ads.txt from the domain of this website"),
        R("Store listing", "per language: text, icon, feature graphic and screenshots come from the publish scripts" + ("; then tick the AI-generated asset labels for every graphic with generated art" if gen_art else ""),
          "an unticked generated asset is a policy risk" if gen_art else ""),
        R("Testing > Internal testing", "Create the tester list (your emails) and tick it on the release", "only testers can install a draft or internal build"),
        R("Production > Countries", "select all, Save", ""),
        R("Publishing overview", "Send for review", "always yours"),
    ]
    admob = []
    if ads:
        admob = [
            R("AdMob > Apps > this app > App settings", "Add the live Play listing (and the App Store one) to the app", "ads are limited until the store listing is linked; only possible once the app is live"),
            R("AdMob > app-ads.txt", "Found. The file is `google.com, pub-<your publisher id>, DIRECT, f08c47fec0942fa0` at the root of the website entered in Store settings", "the crawler needs a few days after the app is live"),
        ]
    later = [
        "**AdMob:** Apple privacy labels (Device ID, Advertising Data, Usage Data), Advertising = Yes in age rating, Play Ads = Yes, Advertising ID = Yes, Data safety rows, UMP consent form, `app-ads.txt`.",
        "**Firebase Analytics:** Apple (Product Interaction, Diagnostics), Play Data safety (App interactions, Diagnostics), privacy policy paragraph (`privacy_policy.py` picks it up).",
        "**In-app purchases:** Apple IAP products + review screenshot, Play Digital purchases = Yes in IARC, price list.",
        "**Online features / accounts:** App access with test login, account deletion URL (Play), Sign in required in Apple review info.",
    ]
    secs = [{"title": "Google Play Console (once per app)", "rows": play}, {"title": "Apple App Store Connect (once per app)", "rows": apple}]
    if admob:
        secs.insert(1, {"title": "AdMob (after the app is live)", "rows": admob})
    return secs, f, later


def render_md(name: str, secs: list, f: dict, later: list) -> str:
    out = [f"# Store form answers for {name}\n",
           "Generated by `store_declarations.py` from the brief and what the project contains. Detected: " + ", ".join(f"{k}={'yes' if v else 'no'}" for k, v in f.items()) +
           ". Re-run after adding ads, analytics or purchases.\n",
           "Legal declarations are yours: read each answer before you give it.\n"]
    for s in secs:
        out += [f"## {s['title']}", "| Form (where) | Answer | Why |", "|---|---|---|"]
        out += [f"| {r['form']} | {r['answer']} | {r['why']} |" for r in s["rows"]]
        out.append("")
    out += ["## What changes when you add things later"] + [f"- {x}" for x in later]
    return "\n".join(out) + "\n"


CSS = """:root{--bg:#f3f5f8;--card:#fff;--fg:#161c27;--mut:#5a6578;--line:#dde2ea;--acc:#1f5fd6;--ok:#14764a}
@media (prefers-color-scheme:dark){:root{--bg:#0f141c;--card:#171e29;--fg:#e8ecf3;--mut:#9aa5b8;--line:#2a3342;--acc:#6ea0ff;--ok:#5fd49a}}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--fg);font:16px/1.5 system-ui,sans-serif;padding:24px 16px 64px}
main{max-width:900px;margin:0 auto}h1{margin:0 0 4px}h2{margin:32px 0 10px}p.n{color:var(--mut);margin:0 0 6px}
.row{display:grid;grid-template-columns:28px 1fr;gap:10px;background:var(--card);border:1px solid var(--line);border-radius:10px;padding:12px 14px;margin:8px 0}
.row.done{opacity:.55}.row input{width:20px;height:20px;margin-top:3px}.f{font-weight:600}.a{margin:4px 0;overflow-wrap:anywhere}
.w{color:var(--mut);font-size:14px}button{font:inherit;font-size:13px;padding:3px 10px;border:1px solid var(--line);border-radius:6px;background:var(--bg);color:var(--fg);cursor:pointer;margin-top:4px}
.prog{color:var(--ok);font-weight:600}"""


def render_html(name: str, secs: list, f: dict) -> str:
    body = []
    n = 0
    for si, s in enumerate(secs):
        body.append(f"<h2>{html.escape(s['title'])}</h2>")
        for ri, r in enumerate(s["rows"]):
            n += 1
            rid = f"r{si}_{ri}"
            body.append(f'<div class="row" data-id="{rid}"><input type="checkbox" id="{rid}" aria-label="done">'
                        f'<div><div class="f">{html.escape(r["form"])}</div><div class="a" id="a_{rid}">{html.escape(r["answer"])}</div>'
                        + (f'<div class="w">{html.escape(r["why"])}</div>' if r["why"] else "")
                        + f'<button type="button" data-copy="a_{rid}">Copy answer</button></div></div>')
    detected = ", ".join(f"{k}: {'yes' if v else 'no'}" for k, v in f.items())
    js = """
const key='decl:'+location.pathname;let st={};try{st=JSON.parse(localStorage.getItem(key)||'{}')}catch(e){}
function upd(){const all=[...document.querySelectorAll('.row')];const d=all.filter(r=>r.querySelector('input').checked).length;
document.getElementById('prog').textContent=d+' of '+all.length+' done';all.forEach(r=>r.classList.toggle('done',r.querySelector('input').checked))}
document.querySelectorAll('.row').forEach(r=>{const i=r.querySelector('input');i.checked=!!st[r.dataset.id];
i.addEventListener('change',()=>{st[r.dataset.id]=i.checked;try{localStorage.setItem(key,JSON.stringify(st))}catch(e){};upd()})});
document.querySelectorAll('[data-copy]').forEach(b=>b.addEventListener('click',()=>{const t=document.getElementById(b.dataset.copy).textContent;
const done=()=>{b.textContent='Copied';setTimeout(()=>b.textContent='Copy answer',1200)};
if(navigator.clipboard)navigator.clipboard.writeText(t).then(done,()=>{});}));upd();"""
    return (f'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">'
            f'<title>{html.escape(name)} store forms</title><style>{CSS}</style></head><body><main>'
            f'<h1>{html.escape(name)}: store forms</h1><p class="n">Detected: {html.escape(detected)}. Read each answer before you give it, these are your legal declarations.</p>'
            f'<p class="n"><span class="prog" id="prog"></span> (ticks are saved in this browser)</p>{"".join(body)}<script>{js}</script></main></body></html>')


def main(game: Path, violence: str, kids: bool) -> None:
    brief = read_brief(game)
    violence = violence or str(brief.get("violence", "none"))
    if violence not in {"none", "cartoon", "realistic"}:
        violence = "none"
    kids = kids or str(brief.get("audience", "")).lower() in {"kids", "children", "family"}
    secs, f, later = build_sections(game, violence, kids)
    name = brief.get("title") or game.name
    d = game / "store"
    d.mkdir(exist_ok=True)
    (d / "declarations.md").write_text(render_md(name, secs, f, later), encoding="utf-8")
    (d / "declarations.html").write_text(render_html(name, secs, f), encoding="utf-8")
    print("wrote", d / "declarations.html", "and", d / "declarations.md")


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    if not args:
        sys.exit(__doc__)
    v = ""
    if "--violence" in sys.argv:
        v = sys.argv[sys.argv.index("--violence") + 1]
        args = [a for a in args if a != v]
    main(Path(args[0]).resolve(), v, "--kids" in sys.argv)
