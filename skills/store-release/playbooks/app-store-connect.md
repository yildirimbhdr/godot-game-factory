# App Store Connect playbook (verified 2026-10-21, individual account, English UI)

1. **Explicit App ID first.** The New App dialog only offers bundle ids that exist in Certificates, Identifiers & Profiles. Device testing with
   Xcode's "XC Wildcard" does not register one. Register it: developer.apple.com/account/resources/identifiers/add/bundleId -> App IDs -> App ->
   description + Explicit bundle id (no extra capabilities for ads/analytics) -> Continue -> Register. The team id on the membership page must equal the preset's
   `application/app_store_team_id` (and Xcode's team).
2. **New App** (Apps -> New App): platform iOS, name (<=30), primary language, the bundle id, SKU, Full Access, Create. The Apple ID in the URL is the app id.
3. **Build**: `scripts/ios_release.sh <game> <work-dir> --upload` (needs the app record). It reports "Uploaded App"; processing in App Store Connect takes ~10-30 min, then the build can be selected on the version page.
4. **Version page** (Distribution -> iOS App Version): per locale promo text, description, keywords, support URL; version number; copyright. Add a language from the
   top-right language menu ("Add <language>"); a new locale inherits the primary text, so select-all and retype. Screenshots tab: the 6.3" slot ("iPhone with Dynamic Island, medium display") needs 1206x2622 or
   1179x2556; 6.9" is optional. Upload via `file_upload`, dismiss the info dialog with OK, wait for the thumbnails (see browser-basics).
5. **App Information** (General): name and subtitle per locale (language menu top right of that section), category, content rights, age ratings, privacy policy URL.
   **App Privacy** (labels), **Pricing and Availability**, **App Review** (contact name, phone, e-mail, notes): all user declarations, propose then ask.
6. A banner "Review the updated Paid Applications Schedule" blocks submitting new apps until the Account Holder accepts it in the Business module. Never accept agreements for the user.
7. The user picks the processed build, answers export compliance (standard HTTPS only = exempt) and presses **Add for Review / Submit**.
