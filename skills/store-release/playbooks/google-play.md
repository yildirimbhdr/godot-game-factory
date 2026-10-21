# Google Play Console playbook (verified 2026-10-21 on a personal account, Turkish UI)

1. Find the account (see browser-basics). `.../developers/<devId>` shows the account name, type (personal/organization) and apps.
2. **Create app**: `.../developers/<devId>/create-new-app`. Fields: app name (<=30), package name (the Godot `package/unique_name`),
   default language, Game/App, Free/Paid, then two **declarations** (developer program policies, US export laws): ask the user, then tick and press "Create app".
   The resulting URL contains the app id: `.../app/<appId>/app-dashboard`. Save both ids in `store/status.json`.
3. The dashboard lists setup tasks; Production stays locked ("complete initial setup first") until they are done. New personal accounts
   (created after 2023-11-13) also need a closed test with >= 12 opted-in testers for 14 days; accounts that already have production apps
   showed no such message. Read the dashboard's own wording before promising a date.
4. Setup tasks (each one is a declaration the user confirms): privacy policy URL, ads (yes), app access, content rating questionnaire,
   target audience, data safety, government/financial/health declarations, news app. Propose answers from the game's real SDKs
   (AdMob: advertising ID + usage; Firebase Analytics: app interactions) and write them into `store/declarations.md` first.
5. Main store listing (per locale): title, short (<=80), full, app icon 512, feature graphic 1024x500, phone screenshots (`play/<locale>/phone/*.png`),
   category, contact email, privacy URL. Add the translated listing via "Manage translations".
6. Release: upload the signed AAB to Internal testing first (`scripts/android_release.sh`), install from the Play link, then promote to Production.
   Version code must increase each upload. The user presses the final "Send for review / Publish".

## Direct URLs and form notes (verified 2026-10-21)
Base: `https://play.google.com/console/u/<n>/developers/<devId>/app/<appId>/`
- `app-content/overview` is the hub: its buttons open each declaration ("Reklam beyanını başlat", "İçerik derecelendirmeleri beyanını başlat", "Hedef kitle ve içerik beyanını başlat", "Veri güvenliği beyanını başlat", plus Advertising ID, government, financial features, health). Guessing sub-URLs mostly fails; click the hub buttons (`find` the button, `left_click` by ref).
  Working direct URLs: `app-content/privacy-policy`, `app-content/testing-credentials`, `app-content/ads-declaration`, `app-content/target-audience-content`, `app-content/content-rating-overview`, `app-content/data-privacy-security`.
- Privacy policy: type the URL, Save. App access: "No restricted parts", Save. Ads: "Yes, contains ads", Save.
- Target audience: for 13+ tick 13-15, 16-17, 18+; the wizard jumps to the summary; Save.
- Content rating (IARC): needs a contact e-mail (shared with rating bodies) and ticking the IARC terms (ask the user first). The questionnaire is sequential: answering one section reveals the next; answer by real clicks on the visible "Hayır", verify "Tamamlandı" badges before "İleri". Save, then Save on the summary. A game with no IAP and no UGC gives PEGI 3 / ESRB Everyone.
- Data safety (5-step wizard): collects/shares = Yes; encrypted in transit = Yes (Google SDKs use HTTPS); account creation = "app does not allow account creation"; deletion method = optional; then pick the data types (AdMob + Firebase Analytics: approximate location, app interactions, device or other IDs, diagnostics) and fill a modal per type (collected/shared, ephemeral?, required/optional, purposes). **This is the user's legal declaration: agree the exact answer set with the user first (write it to `store/declarations.md`) and do not improvise additional types or purposes.** An automatic safety classifier stopped the pilot at this form once.

## Build upload limit
`file_upload` in Claude in Chrome refuses files over 10 MB, so a release AAB (about 90 MB) cannot be uploaded by the agent.
Open Test and release > Internal testing > Create new release, then ask the user to drag the AAB (path under store/builds) into the box. Everything else can be automated.

## Legal declarations can be refused by the permission classifier
Data safety and similar declarations were blocked twice at the click even after the user said "do it". Agree the exact answer set in chat first, then if blocked, hand the form to the user with the answers written in store/declarations.md.
