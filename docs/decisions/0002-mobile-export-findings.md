# 0002 – Mobile export findings (tested 2026-10-21, Godot 4.7.2, macOS arm64, Xcode 26.2)

## Android: works
Signed debug APK (28 MB) exported headless: `godot --headless --path . --export-debug Android out.apk`.
Needed, in order of discovery:
1. Export templates for the exact Godot version in `~/Library/Application Support/Godot/export_templates/<version>/`
   (official `.tpz` from the GitHub release, verified with the published SHA512).
2. **Java SDK path set in Godot Editor Settings** (`export/android/java_sdk_path`). `JAVA_HOME` is ignored.
   JDK 25 worked, JDK 17 is not required.
3. A debug keystore path in Editor Settings that exists (`~/.android/debug.keystore`).
4. Project setting `rendering/textures/vram_compression/import_etc2_astc=true`.
5. A project icon (`application/config/icon`), otherwise an export error is logged.
6. An `export_presets.cfg` with a unique package name.

## iOS: Xcode project export works, simulator does not
- Headless export to an Xcode project works (needs a `app_store_team_id` value, a placeholder is fine for export only).
- The official 4.7.2 iOS template ships a **x86_64-only simulator library**. Building for arm64 simulator
  fails at link time (`_main` undefined). An x86_64 build succeeds, but iOS 26 simulators reject it at
  install ("app needs to be updated").
- Consequence: iOS verification has to happen on a **real device** (arm64, signed with an Apple Development
  team) or with a self-built arm64 simulator library. Neither is needed for day-to-day game development:
  gameplay/UI checks run on desktop via Movie Maker (see decision 0001), Android covers on-device checks.

## Template rules derived from this
- `godot-base/project.godot` must set ETC2/ASTC import, an icon, portrait/landscape explicitly, stretch mode,
  and the renderer (gl_compatibility for widest 2D device support).
- `doctor` skill checks: export templates present for the installed Godot version, Java path in editor
  settings, keystore file exists. It must not edit editor settings without asking.

## Addendum (2026-10-21): Gradle builds (AdMob/Firebase) on Android
Verified on the Unwind pilot (arm64 debug APK, Pixel_7 emulator, Android 16): Firebase initialises, UMP runs, AdMob initialises and requests ads.
- Plugins with native Android libraries need **Gradle build**. JDK 25 fails there (Gradle 8.11.1 cannot read class version 69): set
  `export/android/java_sdk_path` to JDK 17 or 21 (changed with a backup of the editor settings; ask first).
- `scripts/setup-android-gradle.sh <project> [--firebase]` installs the build template, adds `android/build/.gdignore` (without it Godot imports the
  template files and Gradle fails on stray `.import` files) and patches `build.gradle` for `google-services`.
- Preset: Gradle on, arm64-v8a only, min SDK 24 (Firebase), unique package name. Debug APK is ~100 MB because the debug engine library is
  unstripped (76 MB); release is far smaller. The UMP log line "no form(s) configured for the input app ID" means no consent message exists yet in
  AdMob > Privacy & messaging for that app.
- Headless emulator test: `emulator -avd <name> -no-window -no-audio`, `adb install`, `adb logcat --pid=$(adb shell pidof <package>)`.
