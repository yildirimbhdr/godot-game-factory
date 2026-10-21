---
name: playtest-verify
description: Verify a Godot game with scripted touch playtests, screenshots and the Definition of Done checklist. Use before telling the user a game or a UI change is finished, and whenever a playtest fails or is flaky.
---

# Playtest and verify

"It compiles" and "the test passed" are not "done". Look at the screenshots yourself.

## Run
`scripts/playtest.sh <game> <scenario.json> [--seconds N] [--resolution WxH] [--notch] [--lenient-audio]`
Outputs `<game>/.playtest/<scenario>/log.txt`, `marks/*.png`, the recorded `.wav`. Exit code 1 on any failure.
Scenario steps (see `templates/godot-base/autoload/playtest_driver.gd`): `tap`, `tap_text`, `mark`, `expect_text`, `expect_paused`,
`action`, `app_background`, `slide`, `expect_bus_muted`, plus the game-flow steps `tap_group` (tap the i-th node of a group, optional `where` property filter, negative index from the end), `expect_group_count` and `call` (call a method on a group's first node). Use them to play games whose targets move or are not buttons. Marks are saved straight from the viewport (`--shots`); `playtest.sh` keeps the Mac display awake (lesson 0008). Start from `playtest/smoke.json`, then write a scenario for the game's own flow.

Run it at three shapes: default 1080x1920 (`540x960` window), tall `450x975 --notch`, and a short one such as `600x800`.
Open the `marks/*.png` files and check: nothing clipped by the notch, nothing overlapping, text readable, art consistent, juice visible.

## Definition of Done (all must be true)
- [ ] Main menu, on-screen pause button, pause menu, settings (music slider only if music exists), game over, retry, main menu
- [ ] No flat placeholder rectangles: real game art, a game-specific theme (not `FACTORY_DEFAULT`)
- [ ] SFX for every meaningful event; music optional; volume sliders work; no clipping; playtest audio check passes
- [ ] Feedback on every interaction (tween/particles/flash/shake/haptic); scene transitions fade
- [ ] Touch targets >= 150 px, HUD inside `SafeArea` (48 px margin), works on tall and short screens
- [ ] Auto-pause when the app is backgrounded (`app_background` step passes)
- [ ] Console clean of errors/warnings from our code; `ASSETS.md` lists every external asset with source and license
- [ ] Screenshots reviewed by you; tested on a real device when the user has one connected

## The gate (hook) and DOD.md
`hooks/hooks.json` runs `scripts/dod_hook.sh` when Claude tries to stop while a game was edited in the last two hours; it runs
`scripts/dod_check.py` and sends failures back. To pass: run a `smoke*` scenario with strict audio (no `--lenient-audio`) at three
shapes (`playtest.sh` records a stamp per shape), look at the marks, copy `templates/godot-base/DOD.md` into the game and tick only
what you verified (leave unverified items open and say why; items that need a real device stay open until the user confirms).
Editing any source file after the review makes the stamps and DOD.md stale on purpose.

## When something fails or is flaky
Find the logged cause; never retry until green. Write a lesson (`lessons-learned` skill) and encode the fix.
Known harness facts: Movie Maker frame size comes from `override.cfg` (the script handles it); marks use `Engine.get_process_frames()`;
desktop window focus is ignored in playtests; a fresh project needs two import passes.

## On a real device
See `docs/decisions/0003-first-device-test.md` (iOS: export Xcode project, `xcodebuild -allowProvisioningUpdates`, `xcrun devicectl`).
Always confirm with the user which phone is meant.
