---
id: 0027
title: Juice was invisible in every screenshot because playtests zero the animation time
area: testing
severity: minor
status: encoded
---

**What happened:** The game correctly sets `fx_time = 0` under `--playtest=` so rules cannot depend
on animation. But that also disabled the particles, combo label and bloom flash, so every captured
mark showed a static board and the juice looked missing. Time was lost re-checking anchors and
z-order for effects that were working fine.

**Root cause:** one flag served two different purposes — deterministic rule testing and visual
capture.

**Rule:** keep animation off by default in playtests, and expose a `set_fx(value)` method a scenario
can call so capture runs (clips, store screenshots, juice review) re-enable it. Separate the
"correctness" scenario from the "showcase" scenario rather than making one serve both. Also: any
helper that stages game state for a capture must advance the game itself, or an ordinary tick slips
in between staged steps and breaks the sequence being staged (this silently killed a scripted combo).

**Encoded in:** `templates/godot-base/autoload/playtest_driver.gd` header (the `set_fx` convention and the
staging rule, invoked through the existing `call` step), `skills/playtest-verify/SKILL.md` ("Effects in captures,
and staging state").
