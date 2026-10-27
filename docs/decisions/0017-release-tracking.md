# 0017 Release tracking after the first publish

Status: accepted

**Problem:** after the first release a game keeps changing. Nothing recorded which version was in development, which version each store had, or whether the newest version was live, and store build numbers must never repeat.

**Decision:** per game, `store/releases.json` (version, build, history, and per store: version, build, state, track, date) plus `CHANGELOG.md` (Unreleased list). `scripts/release.py` is the only writer: `note`, `bump`, `store`, `show`. Semantic versions; one build number shared by both stores that rises on every bump. The dashboard reads the file and shows development version, each store's version and state, "behind" markers and unreleased notes. Store states are recorded only after the step happened in the console; final publish stays with the user.

**Why not derive it from export_presets.cfg:** presets say what the next build will be, not what any store has.
