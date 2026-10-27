# 0011 - Unwind feedback round 2 (2026-10-21, user on iPhone SE)

User: (1) levels are not a puzzle, every screw can just be removed; (2) screws far too close together, already crowded in level 2; (3) pause screen uses words, games use icons; (4) no dopamine; the main problem is level design.

Changes: hidden-screw placement and spacing in `Figure`; per-level `jars_visible`, `color_seed`, difficulty targets; `check_levels.gd` (naive vs smart win rate, open share, spacing) and `design_levels.gd` + `apply_design.py`; naive win rate now 100% (tutorial) falling to ~5%. IconButton on pause, settings, result and menu with 5 new generated icons (play, speaker, mute, vibrate, empty star; about $0.40, total ~$2.32 of $3). Reward loop: combos with rising pitch and praise words, confetti and shake per jar, landing sparkles, progress bar, release thud, win confetti rain, 1-3 stars saved and shown on the map. Plugin: skill section 6, lessons 0013-0014, `IconButton` in the template, `templates/modules/puzzle-unscrew/tools/`.

Known gaps: the smart player is crude (15-16% on a few levels), real human difficulty untested; no dedicated SFX yet (pitch-shifted Kenney clicks); the tray-full loss is still only tested through the overlay.
