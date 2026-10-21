# 0003 – First on-device test of godot-base (2026-10-21)

Device: iPhone SE (2nd gen), iOS 26.6, no notch. Build: Godot 4.7.2 iOS export to Xcode project,
automatic signing with the user's Apple Development team, installed with `xcrun devicectl`.

Procedure that worked end to end (no manual Xcode UI):
1. `godot --headless --path <project> --export-debug iOS <out>/App.xcodeproj` (preset with real Team ID, `export_project_only=true`)
2. `xcodebuild -project App.xcodeproj -scheme App -destination 'id=<xcode device id>' -allowProvisioningUpdates DEVELOPMENT_TEAM=<id> build`
3. `xcrun devicectl device install app --device <devicectl id> <App.app>` then `... process launch <bundle id>`

Gotchas:
- The device id differs between tools: `xcodebuild -showdestinations` (e.g. 00008030-...) vs `devicectl list devices` (UUID). Use each tool's own id.
- A device can show as `unavailable` while plugged in (locked or not trusted); another paired device may be listed as `available`. Always confirm with the user which phone is meant.

Manual check results (user, on device): menu and settings buttons easy to tap; sliders drag; vibration works;
score increments; pause button position good; pause menu and its buttons work; app returns to the pause menu
after going to Home; game over, retry and menu work; fade transitions feel good; screen fully covered.
Audio is silent as expected (no sound files yet).

Not covered: a notched device (safe area on real hardware), Android.
