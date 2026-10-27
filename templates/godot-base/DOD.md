# Definition of Done - <game>

Fill this in after looking at the playtest screenshots yourself (`.playtest/*/marks/`). The Stop hook
(`scripts/dod_hook.sh`) blocks "done" while a box is open, while this file is older than the last edit,
or while `playtest.sh` has not run `smoke*` scenarios at three screen shapes with strict audio.
Automated half: `python3 ${CLAUDE_PLUGIN_ROOT}/scripts/dod_check.py .`

Last reviewed: YYYY-MM-DD, build/commit: ...

- [ ] Main menu, on-screen pause button, pause menu, settings, result screens, retry, back to menu
- [ ] Level-based: level select screen (locked/current/done, saved progress, win -> Next/Replay/Levels). Endless: saved high score shown on menu and result
- [ ] Icons instead of words on pause, settings and result screens; every icon does what it shows (mute toggles, etc.)
- [ ] Game-specific theme, font, backdrop; no flat placeholder rectangles
- [ ] Every meaningful event has a sound; volume/mute toggles work; sound confirmed on a real device (silent switch off and on)
- [ ] Juice on every interaction (feedback, effects, reward loop); nothing stalls during fast play on the device
- [ ] Touch targets >= 150 px; HUD inside the safe area; checked at 1080x1920, tall notch and short screens
- [ ] Levels/content: difficulty is a real decision (shortcut strategy measured), every level proven solvable
- [ ] Pacing measured, not guessed: time-to-first-death from a no-input run and from a greedy-bot run; a run lasts long enough to show the core mechanic at least twice
- [ ] Console clean; ASSETS.md lists every external asset with source and license
- [ ] (only if the game has ads/analytics) rewarded is opt-in with a visible control, interstitial only at a natural pause and never on a failure; a device run with test ads loaded both formats; events appear in Firebase DebugView; settings has the privacy-options button; `dod_check.py --release` passes before a store build
- [ ] Screenshots of every screen and at least the first, a middle and the last level were looked at
