# Project log

What we decided, why, and what was measured. Read these before changing a tool or asset source.

| Topic | Decision record | Short version |
|---|---|---|
| Godot MCP server | [0001](decisions/0001-godot-mcp-candidates.md) | Compared mkdevkit and raising-heart. Use raising-heart (headless, simple, recent) plus our own scripted touch driver; mkdevkit needs an open editor and an addon in every project |
| Android/iOS export | [0002](decisions/0002-mobile-export-findings.md) | Android debug APK works headless; Godot ignores `JAVA_HOME`; ETC2/ASTC and an icon are required. iOS simulator is unusable (x86_64-only library), test on a real device |
| First device test | [0003](decisions/0003-first-device-test.md) | Template worked on an iPhone SE; one command-line flow from export to launch |
| Sound effects | [0004](decisions/0004-sfx-selection.md) | Retro synth (pyfxr) rejected by ear as artificial, shrill and distorted. Kenney CC0 sounds accepted; the approved sounds and the rejected ones are listed there |
| AI asset generation | [0005](decisions/0005-ai-asset-generation-research.md) | Compared Higgsfield, PixelLab, Ludo, Scenario and direct image APIs with prices. Higgsfield MCP rejected for asset generation (credit markup); PixelLab chosen to trial first |
| UI themes | [0006](decisions/0006-ui-theme-recipes.md) | Themes built from JSON recipes on Kenney packs |
| Art style routing | [0007](decisions/0007-art-style-routing.md) | Style is chosen per game in the brief; pixel art goes to PixelLab, other styles to Kenney or a general image API |
| Unwind: UI base, anchors | [0008](decisions/0008-ui-theme-is-a-base-not-a-final.md) | Theme recipes are a base, adapted per game; pilot game started |
| Pilot log | [0009](decisions/0009-unwind-pilot-log.md) | What the pilot proved and what it changed in the plugin |
| Feedback rounds | [0010](decisions/0010-unwind-feedback-round-1.md), [0011](decisions/0011-unwind-feedback-round-2.md), [0012](decisions/0012-unwind-feedback-round-3.md) | Rebuilt as a real puzzle; level design, lives, mistakes, greedy shortcut |
| Audio, icon, levels | [0013](decisions/0013-unwind-audio-icon-levels.md) | CC0 sounds and music, app icon, 18 levels, tray of 3 |

| Levels, worlds, hints | [0014](decisions/0014-unwind-32-levels-worlds-hints.md) | 32 levels in 4 worlds, solver-backed hint button |
| Ads and analytics | [0015](decisions/0015-ads-and-analytics.md) | AdMob (Poing) + Firebase Analytics (godot-x) behind the `Ads`/`Analytics` autoloads; test ids in debug; consent first; shared Firebase project because of the quota; AdMob app and units created through the web console |

| Store release | [0016](decisions/0016-store-release.md) | Publishing is a plugin skill: generated store graphics and texts, privacy page, builds; owner keeps keys and final submit; Play's 12-tester/14-day rule shapes the schedule |

Lessons (mistakes and the rule that prevents them) are in [`../lessons`](../lessons/README.md). Per-game asset sources and licenses live in each game's `ASSETS.md`.

Maintenance rule: when the user approves, rejects or changes a tool, sound, asset source or style, write or update a record here in the same session.
