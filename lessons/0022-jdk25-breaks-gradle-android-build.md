---
id: 0022
title: Doctor said JDK 25 was fine for Android, but it breaks every Gradle build
area: export
severity: major
status: encoded
---

**What happened:** the earlier export check passed with JDK 25 because a plain APK needs no Gradle. The first Gradle export (needed by AdMob and Firebase) failed with "Unsupported class file major version 69". A stray `android/build` scan then produced `.import` files that broke the build a second time.
**Root cause:** the doctor verified the simplest export path only; the Gradle path was never exercised.
**Rule:** verify the export path the game actually uses (Gradle when any native plugin is present); use JDK 17 or 21; `android/build` always has a `.gdignore`.
**Encoded in:** `skills/doctor/SKILL.md` (Java row), `scripts/setup-android-gradle.sh`, `docs/decisions/0002-mobile-export-findings.md` addendum
