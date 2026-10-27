# 0019 First end-to-end release: Unwind on Google Play and the App Store

Status: accepted (2026-10-22)

**Result:** Unwind 1.1.0 went from an empty folder to a live Google Play production release inside the plugin's workflow; the user reported the production release live about two hours after it was sent for review. The App Store build was in review the same day. Billed generation cost for all art stayed under the $3 genart limit.

**What the full path looked like (each step is now a playbook or script):**
1. Game built from `templates/godot-base`, checked with scripted playtests and the DoD gate (`dod_check.py --release`).
2. Store assets, listing texts (EN/TR) and privacy/support pages from `store_assets.py`, `store_listing_check.py`, `privacy_policy.py`, `site_deploy.sh`.
3. Signed AAB (`android_release.sh`) and iOS upload (`ios_release.sh --upload`), version tracking with `release.py`.
4. Console forms driven through Claude in Chrome (playbooks), with the user confirming every legal declaration and pressing the final submit.

**What made it fast:**
- Everything that repeats is a script with the secrets outside the repo (Keychain password, profile file).
- Declarations are agreed in chat first and written down, so the console step is only typing.
- An established Play developer account (existing production apps) did not hit the 12 testers x 14 days closed-test gate and its production review was far quicker than the documented "up to 7 days". Do not promise this for new personal accounts.

**What still needs the user (cannot be automated, by design):** Play data-safety and advertising-ID declarations (the permission classifier blocks them), uploading the 90 MB AAB (browser tool limit is 10 MB), the Apple Paid Applications agreement, payments/tax, final submit clicks.

**Open at the time of writing:** App Store review result, AdMob GDPR message and store listing, `app-ads.txt`, replacing the App Store screenshots that still show the old design.
