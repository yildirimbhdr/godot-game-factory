#!/usr/bin/env python3
"""Generate a bilingual (EN/TR) privacy policy page for a game from what it actually contains.

  privacy_policy.py <game>      reads <game>/store/policy.json, writes <game>/store/out/site/<slug>/privacy/index.html
                                and .../support/index.html (the App Store needs a support URL with real contact info)

policy.json: {"app": "Unwind", "developer": "Name shown to users", "contact_email": "public contact", "date": "YYYY-MM-DD"}
The SDK paragraphs are included only when the game ships them: addons/admob (ads + consent form) and
addons/godotx_firebase (Analytics). This is a starting text, not legal advice: the owner reads and approves it.
"""
import html, json, sys
from pathlib import Path

EN = {
    "h": "Privacy Policy", "updated": "Last updated", "lang": "Türkçe aşağıda",
    "intro": "{app} is a puzzle game by {developer}. This page explains what information the app and the services it uses handle.",
    "none": "{app} does not require an account, and we do not ask for your name, email address, contacts, photos or precise location.",
    "ads_h": "Advertising",
    "ads": "The game shows ads through Google AdMob. AdMob may use your device's advertising identifier, IP address and ad interaction data to show and measure ads. Where the law requires it (for example the EEA and the UK) a consent form appears first, and you can change your choice later in the game's Settings under \"Privacy options\". See Google's policy: https://policies.google.com/technologies/ads",
    "an_h": "Analytics",
    "an": "We use Firebase Analytics to understand how the game is used, for example which levels are started and finished and how often hints are used. Where consent is required, analytics stay off until you agree. See https://policies.google.com/privacy and https://firebase.google.com/support/privacy",
    "kids_h": "Children",
    "kids": "{app} is not directed to children under 13, and we do not knowingly collect personal information from them.",
    "rights_h": "Your choices and rights",
    "rights": "You can reset your advertising identifier or limit ad tracking in your device settings, change your consent in the game's Settings, or uninstall the game. Depending on where you live you may have the right to access or delete data linked to you; contact us and we will help. Game progress is stored only on your device.",
    "contact_h": "Contact", "contact": "Questions or requests: {email}",
    "changes": "We may update this policy; the date above shows the latest version.",
}
TR = {
    "h": "Gizlilik Politikası", "updated": "Son güncelleme", "lang": "English above",
    "intro": "{app}, {developer} tarafından geliştirilen bir bulmaca oyunudur. Bu sayfa, uygulamanın ve kullandığı hizmetlerin hangi bilgileri işlediğini açıklar.",
    "none": "{app} için hesap gerekmez; adınızı, e-posta adresinizi, kişilerinizi, fotoğraflarınızı veya kesin konumunuzu istemeyiz.",
    "ads_h": "Reklamlar",
    "ads": "Oyun, Google AdMob üzerinden reklam gösterir. AdMob, reklamları göstermek ve ölçmek için cihazınızın reklam kimliğini, IP adresinizi ve reklam etkileşimi verilerini kullanabilir. Yasanın gerektirdiği yerlerde (örneğin AEA ve Birleşik Krallık) önce bir onay formu görünür; tercihinizi daha sonra oyunun Ayarlar bölümündeki \"Privacy options\" düğmesinden değiştirebilirsiniz. Google'ın politikası: https://policies.google.com/technologies/ads",
    "an_h": "Analitik",
    "an": "Oyunun nasıl kullanıldığını anlamak için (örneğin hangi bölümlerin başlatıldığı ve bitirildiği, ipucunun ne sıklıkla kullanıldığı) Firebase Analytics kullanırız. Onay gereken yerlerde siz kabul edene kadar analitik kapalı kalır. Bkz. https://policies.google.com/privacy ve https://firebase.google.com/support/privacy",
    "kids_h": "Çocuklar",
    "kids": "{app}, 13 yaşın altındaki çocuklara yönelik değildir ve onlardan bilerek kişisel bilgi toplamayız.",
    "rights_h": "Seçimleriniz ve haklarınız",
    "rights": "Cihaz ayarlarınızdan reklam kimliğinizi sıfırlayabilir veya reklam takibini sınırlayabilir, oyunun Ayarlar bölümünden onayınızı değiştirebilir ya da oyunu kaldırabilirsiniz. Yaşadığınız yere göre sizinle ilişkili verilere erişme veya silme hakkınız olabilir; bize yazın, yardımcı olalım. Oyun ilerlemeniz yalnızca cihazınızda saklanır.",
    "contact_h": "İletişim", "contact": "Soru ve talepler için: {email}",
    "changes": "Bu politikayı güncelleyebiliriz; yukarıdaki tarih en son sürümü gösterir.",
}


def section(t: dict, p: dict, ads: bool, analytics: bool, lang_id: str) -> str:
    e = html.escape
    parts = [f'<section id="{lang_id}"><h1>{e(t["h"])}</h1>',
             f'<p class="meta">{e(t["updated"])}: {e(p["date"])}</p>',
             f'<p>{e(t["intro"].format(app=p["app"], developer=p["developer"]))}</p>',
             f'<p>{e(t["none"].format(app=p["app"]))}</p>']
    if ads:
        parts += [f'<h2>{e(t["ads_h"])}</h2>', f'<p>{e(t["ads"])}</p>']
    if analytics:
        parts += [f'<h2>{e(t["an_h"])}</h2>', f'<p>{e(t["an"])}</p>']
    parts += [f'<h2>{e(t["kids_h"])}</h2>', f'<p>{e(t["kids"].format(app=p["app"]))}</p>',
              f'<h2>{e(t["rights_h"])}</h2>', f'<p>{e(t["rights"])}</p>',
              f'<h2>{e(t["contact_h"])}</h2>', f'<p>{e(t["contact"].format(email=p["contact_email"]))}</p>',
              f'<p>{e(t["changes"])}</p></section>']
    return "\n".join(parts)


def build(game: Path) -> Path:
    p = json.loads((game / "store" / "policy.json").read_text())
    # Missing fields come from the user's profile (scripts/gf_profile.py), so they are asked once, not per game.
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    import gf_profile
    prof = gf_profile.load()
    p.setdefault("developer", gf_profile.publisher_line(prof))
    p.setdefault("contact_email", prof["public_contact_email"])
    for k in ("app", "developer", "contact_email", "date"):
        if not p.get(k):
            sys.exit(f"policy.json is missing '{k}'")
    ads = (game / "addons" / "admob").is_dir()
    analytics = (game / "addons" / "godotx_firebase").is_dir()
    css = ("body{font:17px/1.55 system-ui,sans-serif;max-width:720px;margin:2rem auto;padding:0 1rem;color:#2b2540;background:#fff8f0}"
           "h1{color:#5b4b8a}h2{margin-top:1.6rem;color:#5b4b8a}.meta{color:#7a6f99}section+section{margin-top:3rem;border-top:2px solid #e4d6fa;padding-top:1rem}a{color:#5b4b8a}")
    body = section(EN, p, ads, analytics, "en") + "\n" + section(TR, p, ads, analytics, "tr")
    page = (f'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">'
            f'<title>{html.escape(p["app"])} - Privacy Policy</title><style>{css}</style></head><body>{body}</body></html>')
    slug = "".join(c for c in p["app"].lower() if c.isalnum())
    site = game / "store" / "out" / "site" / slug
    (site / "privacy").mkdir(parents=True, exist_ok=True)
    (site / "support").mkdir(parents=True, exist_ok=True)
    (site / "privacy" / "index.html").write_text(page, encoding="utf-8")
    support = (f'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">'
               f'<title>{html.escape(p["app"])} - Support</title><style>{css}</style></head><body><section>'
               f'<h1>{html.escape(p["app"])} - Support / Destek</h1>'
               f'<p>Questions, bug reports or privacy requests: <a href="mailto:{html.escape(p["contact_email"])}">{html.escape(p["contact_email"])}</a></p>'
               f'<p>Soru, hata bildirimi veya gizlilik talepleri için: <a href="mailto:{html.escape(p["contact_email"])}">{html.escape(p["contact_email"])}</a></p>'
               f'<p>{html.escape(p["developer"])}</p><p><a href="../privacy/">Privacy Policy / Gizlilik Politikası</a></p></section></body></html>')
    (site / "support" / "index.html").write_text(support, encoding="utf-8")
    return site


if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    print("wrote", build(Path(sys.argv[1]).resolve()), "(privacy/ and support/)")
