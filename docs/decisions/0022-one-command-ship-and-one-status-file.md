# 0022: ship.sh, a form answer sheet, and one status file per game

Date: 2026-11-20. Status: accepted (user request after the Cat Logic release).

**Problem:** publishing worked (fastlane, no browser) but every release repeated the same manual checks, the answers for the store forms had to be worked out again, and each game kept its own differently shaped `store/status.json`, so "which game is where" had no single answer. Three mistakes from the Cat Logic release were all silent: Godot dropped the `[admob]` section of `project.godot`, `publish_listing.sh` failed on an empty version code, and a draft app needed one more Play permission.

**Decision:**
1. `scripts/play_publish/ship.sh <game>`: preflight (definition of done for the platform being shipped, package names, listing, graphics, live privacy/support pages, `app-ads.txt`, keys), then `publish_new.sh` or `publish_update.sh` chosen from the status file, an AAB check before upload (the real AdMob app id inside the manifest), recording of the upload, and the printed list of manual steps. `--dry` uploads nothing and restores `export_presets.cfg`. `dod_check.py --release --platform android|ios` stops an Android-only release from failing on iOS ids.
2. `store_declarations.py` reads `brief.json` as well as the project and writes `store/declarations.html`: one page, a copy button per answer, ticks kept in the browser.
3. `scripts/gf_status.py`: `store/status.json` schema 2 with the same fields in every game (Play and App Store state with `source` and `verified_on`, AdMob and Firebase ids read from the project, the manual steps, the old keys under `legacy`). `release.py store`, the publish scripts and `dashboard.py` all use it. A state recorded from an old note is marked `legacy note`, and steps of a store that is in review or live are ticked as `inferred`, so unverified facts are not mistaken for checked ones.

**Not changed:** nothing in the Play Console flow is automated further. Legal declarations, permissions, testers, "Send for review" and linking the store listing in AdMob stay with the user. No browser is used for publishing.

**Next candidates:** an App Store Connect lane for the same ship flow (deliver/pilot with an API key), release-time checks for iOS ids, reading Firebase events back to tune levels.
