---
name: game-start
description: Guided start of a new game, or resume of an unfinished one (the /new-game command). Asks the brief step by step, then creates the project folder with GDD.md, ART_BRIEF.md, PLAN.md and the store skeleton, and begins building. Use when the user says "oyun yapalım", "yeni oyun", "oyun yapmaya başla", "make a game", "start a game" or runs /new-game.
---

# Game start (the director)

One entry point that keeps the fixed factory order. It owns the questions, the files and the phase list;
the other skills do the work of each phase. Never write game code before the user approved the summary (step 6).
Paths are relative to `${CLAUDE_PLUGIN_ROOT}`. Ask in the user's language (Turkish if they write Turkish). Files stay English.

## 0. Resume or start
- Look for `PLAN.md` in the current folder, then in the profile `workspace` folders (`ls <workspace>/*/PLAN.md`).
  If one has unticked phases, say "`<game>` is at phase N: <where we stopped>. Continue?" and jump to that phase (section 7). Do not ask the brief again.
- Otherwise start a new game. Read `lessons/` once (every file is a mistake that already happened).

## 1. Machine check (silent unless something is missing)
Run the `doctor` checks (read-only). Stop and list what is missing if Godot, ffmpeg, python3, node or git are absent; install nothing without a yes.
Run `python3 scripts/gf_profile.py show`. Only `workspace` is needed now: if empty, ask where games should live (default `~/Desktop/games`) and save it with `gf_profile.py set workspace <path>`.
Publisher fields (developer name, brand, public email) are asked later, in phase 9, not now.

## 2. Idea
Use AskUserQuestion. If the user already gave an idea (in the command text or chat), restate it in two sentences and ask for a correction.
If not: offer "I have an idea" / "Give me 6 ideas" (then follow `game-ideation`). Capture: the core loop in one sentence, and 1-3 things we will NOT build.

## 3. Scope (one AskUserQuestion call, 4 questions, each a separate answer; never assume, never skip)
1. Structure: levels with a level map / endless with a high score.
2. AdMob ads: yes / no.   3. Firebase Analytics: yes / no.   4. In-app purchases: yes / no.
Then a second call: orientation (portrait default / landscape), languages (English only / English + Turkish / other), music (no / yes), stores (both / Google Play only / App Store only).
Yes to ads, analytics or IAP means the `monetization` skill runs at phase 7 and the user needs AdMob/Firebase accounts; say that in one line.

## 4. Art (see `art-direction` and decision 0007: one style per game, the source follows the style)
Ask: style (pixel art / flat clean 2D / hand-painted / other), source (PixelLab / Gemini via `genart.py` / free CC0 packs / own files), mood in one short answer.
If the source is Gemini, `genart.py` needs a credit limit the user sets (`genart.py --set-limit N`); never raise it yourself. If PixelLab, check the MCP is connected.
Palette and perspective are proposed by you in the summary, not asked.

## 5. Name
Propose 3 titles (brand/mechanic words, no world or character theme words, 30 characters or fewer; see store-release "Naming and ASO"),
the folder slug and the bundle id `com.<brand>.<slug>` (brand from the profile, else ask once). The user picks or types one.

## 6. Summary and approval (the gate)
Show ONE table: title, slug, folder, idea, core loop, structure, will-not-build, orientation, languages, music, ads/analytics/IAP, stores,
art style/source/mood/palette, bundle id. Ask "Approve and create the project?" (Approve / Change something).
Only on Approve: write `brief.json` to the scratchpad with `"approved": true` and run
`python3 scripts/new_game.py --brief <brief.json> --dest <workspace>`. The script refuses an unapproved brief.
It creates the folder from `templates/godot-base`, GDD.md, ART_BRIEF.md, PLAN.md, brief.json, store/status.json, store/listing.json (empty skeleton), imports, and prints the open DoD items.

## 7. Build (phases in PLAN.md, in order; the other skills do the work)
| Phase | Skill / tool | Gate before ticking |
|---|---|---|
| 3 Art | `art-direction`, `asset-pipeline` | anchor asset approved by the user, then the set; ASSETS.md filled |
| 4 Core loop | `godot-scaffold` section 3, `physics-puzzle-design` if it fits | a screenshot of the running game that you looked at |
| 5 Theme, UI, sound | `asset-pipeline`, `build_theme.py`, `sfx.sh` | icon-only HUD, SFX for every event |
| 6 Content | `godot-scaffold`, game-specific tools | pacing measured (no-input and greedy-bot), every level solvable |
| 7 Monetization | `monetization` | only if the brief says yes; otherwise tick as "not applicable" |
| 8 Definition of Done | `playtest-verify`, `dod_check.py` | passes, DOD.md ticked, user played it on a device |
| 9 Store package | `store-release`, `dashboard` | `dod_check.py --release` passes; the user approves visuals and texts |
| 10 Publish | `store-release/playbooks/fastlane.md` | builds uploaded; the user does the declarations and the final submit |

After every phase: tick its box in PLAN.md, rewrite "Where we stopped" in one or two lines, add a dated log line, and record each user approval or rejection in `GDD.md` decisions.
Show the user the running game early (phase 4) and never say "done" without the Stop hook's DoD passing.
If the user changes the brief later (more worlds, ads added), edit GDD.md and `brief.json` and log the change in PLAN.md.

## Rules
- The user decides every question above; you only propose defaults. Money, legal declarations and final store submits stay with the user.
- Keep questions short and in batches of at most four. Do not ask what the profile or an earlier answer already tells you.
- A mistake that reaches the user becomes a lesson (`lessons-learned` skill).
