---
id: 0033
title: Playtest recordings stopped after a random number of frames even for the untouched template
area: testing
severity: major
status: encoded
---

**What happened:** The same smoke scenario on the same template recorded 260, 69, 150, 110 frames in a row. Expectations passed every time;
screenshots after the cut were stale copies of the last drawn frame. Lessons 0008 and 0031 had named two causes (display sleep, a variable font);
this was a third: the window being hidden or the machine busy, with no code change involved.

**Root cause:** Movie Maker only records what macOS actually presents, and playtest.sh trusted the run without counting frames.

**Rule:** a run only counts when it recorded the expected number of frames. `playtest.sh` now passes `--always-on-top`, compares `N frames at 20 FPS`
with `seconds * 20`, retries up to three times and otherwise exits with `PLAYTEST UNRELIABLE`.

**Encoded in:** `scripts/playtest.sh`, `skills/playtest-verify/SKILL.md`.
