---
id: 0024
title: iOS release failed three ways that device testing never showed
area: export
severity: major
status: encoded
---

**What happened:** (1) the App Store Connect "New App" dialog did not list `com.bahadir.unwind`: device tests had used Xcode's "XC Wildcard", so no explicit App ID existed. (2) `xcodebuild archive` of Godot's release export failed with "conflicting provisioning settings": Godot writes a manual Apple Distribution identity while the project is automatically signed. (3) The upload needs the App Store Connect record to exist first.
**Root cause:** the iOS path was only ever verified with development builds on a device.
**Rule:** before the first release, register the explicit App ID and create the ASC record; archive with the Development identity + automatic style and let `-exportArchive` do the distribution signing and upload.
**Encoded in:** `scripts/ios_release.sh`, `skills/store-release/playbooks/app-store-connect.md`
