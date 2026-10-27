---
id: 0052
title: Play Console run for Slide Buddies: what the second full pass looked like and what to do differently
area: workflow
severity: minor
status: encoded
---

**What happened:** Creating the app, all App content declarations, store settings, listing (en + tr) and production countries took one long session. The legal declaration checkboxes on "create app" were refused by the permission classifier once ("Consent given for the user" even though the user had approved in chat) and went through after the user restated explicit approval in chat. Release setup needed an Android Release preset in the project (the iOS-only project had none), JDK 17 in Godot's editor settings and `setup-android-gradle.sh`; the 51 MB AAB built in about two minutes.
**Root cause:** the playbook covered the console forms but not the project-side Android setup for a game that started iOS-first, and not the explicit-consent wording the classifier wants.
**Rule:** before opening Play Console, make sure the project has an "Android Release" preset (copy from a published game, set `package/unique_name`, version code 1, exclude `store/*`, `tools/*`, `build/*`), run `setup-android-gradle.sh` and `android_release.sh` and keep the AAB in `store/builds/`. Ask the user once for an explicit sentence of approval for the declarations; on a refusal, restate it in chat and retry. The sequence that worked: privacy URL, app access (No), ads (No), IARC (Game; violence section answered consistently with the Apple age rating), target audience 13+, data safety (no data), advertising ID (No), government (No), finance and health ("none" boxes at the bottom of the lists), store settings (category Puzzle), listing per language, AI-generated asset labels on every uploaded graphic, production countries (select all). The AAB upload stays with the user (10 MB tool limit).
**Encoded in:** `skills/store-release/playbooks/google-play.md` (Run order and traps)
