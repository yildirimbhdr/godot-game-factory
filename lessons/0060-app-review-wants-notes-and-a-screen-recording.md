---
id: 0060
title: App Review now rejects apps without review notes and a screen recording (and the build must be attached)
area: workflow
severity: major
status: encoded
---

**What happened:** Unwind 1.1.0 was REJECTED with "We need additional information to better understand the app" (2026-11). Looking at Cat Logic's App Store Connect version showed the same gaps: the build was uploaded and processed but **not attached** to the version (`deliver` with `skip_binary_upload` never attaches it), App Review Information (contact, notes) was empty, and there was no screen recording.
**Rule:** before any App Store submission the Notes field must hold: (1) a link to a screen recording made on a physical device with the latest iOS, from launch through the typical flow, (2) purpose and target audience, (3) how to reach the main features (login, sample files), (4) the external services used, (5) regional differences, (6) documentation if regulated or protected material. The recording cannot be generated: the owner records it (Control Center > Screen Recording), hosts it behind a link and saves the URL in `store/review_video_url.txt`.
**Also learned:** the App Store Connect API refuses review-contact changes without a phone number (`contactPhone` is required), and a brand-new version has no review detail record (fastlane issue 20538); `ensure_review_detail` creates one.
**Encoded in:** `scripts/review_notes.py` (generate, apply to any app's editable version, check), `fastlane_prepare.py` (notes and contact go with the metadata), lane `attach_build`, `preflight.py --platform ios` (FAIL without the recording link), `ship_ios.sh` (attaches the build), profile key `review_phone`.
