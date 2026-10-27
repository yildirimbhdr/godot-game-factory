---
name: playtest-verify
description: Verify a Godot game with scripted touch playtests, screenshots and the Definition of Done checklist. Use before telling the user a game or a UI change is finished, and whenever a playtest fails or is flaky.
---

# Playtest and verify

"It compiles" and "the test passed" are not "done". Look at the screenshots yourself.

## Testing must be visible and evidenced (lesson 0029)
The user watches the Godot window open and the game being played; that is what "I tested it" means here.
- A test is `scripts/playtest.sh` (Godot window, scripted touches, screenshots) or `scripts/play.sh <game> [scenario.json]`
  (live window the user can watch or play). `godot --headless`, GDScript/Python unit scripts and simulators are build checks
  (import, level solvability), never a playtest, and must not be described as one.
- Run `play.sh` with the scenario in front of the user at least once per milestone (core loop works, a new screen, final check).
- Every "tested" report names the scenario, the log path and the marks you opened, and says in one line what each mark shows
  (e.g. "03_game.png: board with 6 pieces, score 0, pause button top right"). No marks opened, no claim.
- If the Godot window cannot open (no display, crash), say so and stop; do not substitute another kind of check.

## Run
`scripts/playtest.sh <game> <scenario.json> [--seconds N] [--resolution WxH] [--notch] [--lenient-audio]`
Outputs `<game>/.playtest/<scenario>/log.txt`, `marks/*.png`, the recorded `.wav`. Exit code 1 on any failure.
Scenario steps (see `templates/godot-base/autoload/playtest_driver.gd`): `tap`, `tap_text`, `mark`, `expect_text`, `expect_paused`,
`action`, `app_background`, `slide`, `expect_bus_muted`, plus the game-flow steps `tap_group` (tap the i-th node of a group, optional `where` property filter, negative index from the end), `expect_group_count` and `call` (call a method on a group's first node). Use them to play games whose targets move or are not buttons. Marks are saved straight from the viewport (`--shots`); `playtest.sh` keeps the Mac display awake (lesson 0008). Start from `playtest/smoke.json`, then write a scenario for the game's own flow.

Run it at three shapes: default 1080x1920 (`540x960` window), tall `450x975 --notch`, and a short one such as `600x800`.
Open the `marks/*.png` files and check: nothing clipped by the notch, nothing overlapping, text readable, art consistent, juice visible.

`playtest.sh` now does this itself (always-on-top window, frame count check, up to three retries, `PLAYTEST UNRELIABLE` when it cannot get a full recording; lesson 0033).
Before trusting marks by hand, compare the log line `N frames at 20 FPS` with `--seconds * 20`. Fewer frames means the recording stopped
early (variable font, lesson 0031; very long static scenarios) and later marks are stale copies even though expectations passed.
A mark with the same file size as the previous one is suspect. Keep scenarios short; split long ones (e.g. all-levels autoplay).

Many levels or many screens: do not chain timed taps (lesson 0032). Give the game an autoplay hook that uses the real UI flow
(see `light-puzzle/game.gd`), and finish with an expectation only the final state can satisfy.

## Definition of Done (all must be true)
- [ ] Main menu, on-screen pause button, pause menu, settings (music slider only if music exists), game over, retry, main menu
- [ ] Level-based game: level select screen with locked/current/done and saved progress (endless game: saved high score)
- [ ] No flat placeholder rectangles: real game art, a game-specific theme (not `FACTORY_DEFAULT`)
- [ ] SFX for every meaningful event; music optional; volume sliders work; no clipping; playtest audio check passes
- [ ] Feedback on every interaction (tween/particles/flash/shake/haptic); scene transitions fade
- [ ] Touch targets >= 150 px, HUD inside `SafeArea` (48 px margin), works on tall and short screens
- [ ] Auto-pause when the app is backgrounded (`app_background` step passes)
- [ ] Pacing measured: time-to-first-death from a no-input run and a greedy-bot run; a run shows the core mechanic at least twice
- [ ] Console clean of errors/warnings from our code; `ASSETS.md` lists every external asset with source and license
- [ ] Screenshots reviewed by you; tested on a real device when the user has one connected

## The gate (hook) and DOD.md
`hooks/hooks.json` runs `scripts/dod_hook.sh` when Claude tries to stop while a game was edited in the last two hours; it runs
`scripts/dod_check.py` and sends failures back. To pass: run a `smoke*` scenario with strict audio (no `--lenient-audio`) at three
shapes (`playtest.sh` records a stamp per shape), look at the marks, copy `templates/godot-base/DOD.md` into the game and tick only
what you verified (leave unverified items open and say why; items that need a real device stay open until the user confirms).
Editing any source file after the review makes the stamps and DOD.md stale on purpose.

## Effects in captures, and staging state (lesson 0027)
Animation time is zeroed under `--playtest=` so rules cannot depend on it; that also hides particles, combo labels and flashes,
so a correctness run's marks legitimately show a static board. Do not go hunting anchors or z-order for effects that work.
A game exposes `set_fx(value)` on its `game` node; a capture run (clip, store screenshot, juice review) re-enables effects as
its first step: `{"t": 0.1, "do": "call", "group": "game", "method": "set_fx", "args": [1.0]}`. Keep the correctness scenario
and the showcase scenario in separate files instead of making one serve both. Any helper that stages state for a capture must
advance the game itself, or an ordinary tick slips in between staged steps and breaks the sequence being staged.

## When something fails or is flaky
Find the logged cause; never retry until green. If an assertion about UI state fails, read the mark screenshot before changing
UI code: the game may simply be in a different state than the scenario assumed (a dead player legitimately does not pause -
lesson 0026). Write a lesson (`lessons-learned` skill) and encode the fix.
Known harness facts: Movie Maker frame size comes from `override.cfg` (the script handles it); marks use `Engine.get_process_frames()`;
desktop window focus is ignored in playtests; a fresh project needs two import passes.

## On a real device
See `docs/decisions/0003-first-device-test.md` (iOS: export Xcode project, `xcodebuild -allowProvisioningUpdates`, `xcrun devicectl`).
Always confirm with the user which phone is meant.

## Level-based games (lessons 0043-0045)
- Rewrite `playtest/smoke.json` as soon as the placeholder game is replaced (menu, settings sliders, Play, `level_node`, `pause_button`, Resume, app_background, `autosolve`, clear, map); the DoD gate needs it green at the three screen shapes.
- `level_unlocked` is a count; a level N store frame needs `level_unlocked: N` and `level_node` index N-1.
- Record another language with `GF_LANG=tr scripts/playtest.sh ...`.
