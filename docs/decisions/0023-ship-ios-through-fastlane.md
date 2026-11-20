# 0023: iOS release through fastlane (ship_ios.sh)

Date: 2026-11-20. Status: accepted (user request, after the Android route in 0022); lanes untested against a live account.

**Problem:** the Android release is one command, the iOS one was a set of loose parts (`ios_release.sh`, a Fastfile generated per game, manual console clicks). Apple needs an App Store Connect API key, an app record that no API can create, and a processing wait between the upload and the version page.

**Decision:** `scripts/apple_publish/ship_ios.sh` mirrors `ship.sh`: preflight (`preflight.py --platform ios`), regenerate the fastlane project, read-only `status` lane (also proves the key works and the app record exists), upload through `ios_release.sh`, `wait_build` lane until the build is VALID, `metadata` lane for texts and screenshots, record in `store/status.json`. `ship.sh --platform ios|both` dispatches to it. Submitting for review needs the explicit `--submit`; by default "Add for Review" stays the owner's click. The Fastfile moved into `templates/fastlane/Fastfile.tmpl` with a version line so existing games can be upgraded without losing a hand-edited file. `dod_check.py` no longer counts `store/` and `fastlane/` as game sources (their copied images made DOD.md look stale).

**Not changed:** the app record, App Privacy, age rating, review contact and "Add for Review" remain manual. No browser is used for publishing.

**Also (same day):** `gf_status.py sync-apple` reads the truth from App Store Connect (template `Fastfile.probe`). It showed that notes were wrong in two places (Unwind is REJECTED, not in review; Snake Fill has no app record). The API key can register a Bundle ID but cannot create the app record.

**Open:** the lanes `wait_build`/`metadata`/`submit` have to meet a real account once; an iOS AdMob app and units are needed before a game with ads passes the iOS preflight.
