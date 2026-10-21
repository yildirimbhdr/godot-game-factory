# 0013 - Unwind audio, icon and 10 more levels (2026-10-21, user request)

- SFX: 7 new game events built from CC0 Kenney packs (interface-sounds, impact-sounds, music-jingles) inside the user's liked set; candidates B-D per event in `audition-unwind-sfx/`; A is wired. The user still has to audition them by ear.
- Music: gameplay = MintoDog Cozy Puzzle In-Game 2 (CC0, ogg), menu/map = OwlishMedia Happy Clappy Loop (CC0, wav), both verified on their OpenGameArt pages, loudness-normalised by `music.sh`.
- App icon: Gemini 1:1 full-bleed, big pastel screw on a lavender/peach gradient (2 candidates, `audition-unwind/appicon/`, candidate 1 used). `genart.py` got `--aspect`.
- Levels 9-18: Balloon, Fish, Key, Pine, Crown, Mushroom, Sailboat, Castle, Cat, Diamond, same design pipeline (checks + colour search + solver). Hidden-screw cap per covering piece lowered to 2 so front pieces keep room for their own screws.

## Later the same day
- Tray reduced from 5 to 3 slots (user); all 18 levels re-searched, all solvable, shortcut win rates 100/48/30/19/12/8/6/4... percent.
- iOS silent switch muted all audio: session category set to Playback (lesson 0017). Audio icons became mute toggles (lesson 0018).
- Definition of Done gate added (`hooks/hooks.json`, `scripts/dod_hook.sh`, `scripts/dod_check.py`, `templates/godot-base/DOD.md`); reusable pieces moved to `templates/modules/`. The marketplace/GitHub release is intentionally postponed (user).
