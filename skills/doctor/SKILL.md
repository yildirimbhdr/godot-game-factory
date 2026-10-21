---
name: doctor
description: Check that the machine has everything game-factory-godot needs (Godot, export templates, Java path, Android SDK, keystore, Xcode, ffmpeg, node) and report what is missing. Use at first setup or when a run or export fails.
---

# Doctor

Run read-only checks, then print one table: item, status (OK / MISSING / WRONG), and the fix.
Never install or edit anything without the user's explicit approval. Editor settings and downloads
always need a yes first.

## Checks

| Item | How | Needed for |
|---|---|---|
| Godot 4.x | `godot --version` (also try `/Applications/Godot.app/Contents/MacOS/Godot`) | everything |
| node 18+ and git | `node -v`, `git --version` | the Godot MCP server |
| python3 3.9+ | `python3 -V` | SFX generation (`scripts/setup-audio-tools.sh` creates a private venv with pyfxr), theme/music scripts |
| Godot MCP server built | `scripts/setup-godot-mcp.sh` (idempotent, pinned commit, ~5 s first run) | project checks, screenshots |
| ffmpeg + ffprobe | `ffmpeg -version` | sound/music/theme scripts. Libvorbis is not required (OGG is copied, not re-encoded) |
| Export templates for the installed Godot version | `~/Library/Application Support/Godot/export_templates/<version>/` must contain `android_debug.apk` / `ios.zip` | any export |
| Android SDK | `export/android/android_sdk_path` in editor settings points to an SDK with platform-tools, a platform, build-tools | Android export |
| Java path | `export/android/java_sdk_path` in `~/Library/Application Support/Godot/editor_settings-<major.minor>.tres` is non-empty. `JAVA_HOME` is ignored by Godot. Use **JDK 17 or 21**: JDK 25 builds a plain APK but breaks Gradle builds ("Unsupported class file major version 69"), and AdMob/Firebase need Gradle. Homebrew `openjdk@17` or Android Studio's bundled JBR (21) are fine | Android export |
| Debug keystore | the file named by `export/android/debug_keystore` exists | Android export |
| Xcode + signing identity | `xcodebuild -version`, `security find-identity -v -p codesigning` | iOS export |

## Optional services
| Item | How | Needed for |
|---|---|---|
| PixelLab token | env var `PIXELLAB_API_TOKEN` is set (never print it) | pixel-art asset generation through the PixelLab MCP |

## Fixes (ask first)

- Templates: download the official `.tpz` for the exact version from the godot GitHub release, verify against
  `SHA512-SUMS.txt`, unzip into `export_templates/<version>/` (the folder name is `4.7.2.stable` style).
- Editor settings: back the file up (`.bak-gamefactory`) before changing the Java or keystore path.
- Missing Android pieces: use `sdkmanager` for the packages named in the Godot docs for that version.

## Known limits (do not "fix")

- The official iOS template has no arm64 simulator library; iOS must be tested on a real device.
- Per-user values (Apple Team ID, device) are never stored in this repo. Ask the user or read their own config.

See `docs/decisions/0002-mobile-export-findings.md`.
