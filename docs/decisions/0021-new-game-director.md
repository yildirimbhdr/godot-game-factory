# 0021: One guided entry point, /new-game

Date: 2026-10-27. Status: accepted (user request).

**Problem:** the pieces existed (ideation, scaffold, art direction, store release) but nothing owned the order or the questions, so the user had to know which skill to call and the agent sometimes skipped steps (lesson 0028). Every new machine or new game repeated the same questions in free form.

**Decision:** a command `/new-game` and a skill `game-start` act as the director: machine check, idea, scope, art, name, one summary that the user approves, then `new_game.py --brief`. The script, not the model, writes GDD.md, ART_BRIEF.md, PLAN.md, brief.json, store/status.json and a store/listing.json skeleton, so this costs no tokens. It refuses a brief without `"approved": true`. PLAN.md holds the phase checklist and "where we stopped", which makes `/new-game` resumable in a new session. `dod_check.py` requires the `Approved:` line and, with `--release`, phases 1-8 ticked.

**Not changed:** the other skills stay as they are and do the work of each phase. Money, legal declarations and final store submits stay with the user.

**Also:** the Android upload keystore path and Keychain service now come from the per-user profile (`gf_profile.py get`), so no machine-specific name is baked into scripts.
