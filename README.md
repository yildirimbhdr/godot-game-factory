# game-factory-godot

Tell Claude Code "make me a game" and get a finished-looking 2D mobile game (Android and iOS) made with Godot 4:
splash, menu, settings, sound, effects, levels, tested by actually playing it on screen.

## How it works

1. **Install** (once), restart Claude Code, then say "run the doctor":
   ```
   /plugin marketplace add yildirimbhdr/godot-game-factory
   /plugin install game-factory-godot@game-factory
   ```
2. **Start:** type `/new-game` (or just say "let's make a game"). Claude asks short questions in batches and shows one summary to approve.
   Run `/new-game` inside an unfinished game's folder to resume it from `PLAN.md`.
3. **Idea:** bring your own, or ask for 6 ideas from different genres.
4. **Project:** after your approval the starter template is copied with `GDD.md`, `ART_BRIEF.md`, `PLAN.md` (phase checklist, where we stopped) and a store skeleton
   (splash, menu, pause, settings, English/Turkish, how-to card).
5. **Look and sound:** art direction, theme and sound effects for this game.
6. **Build and test:** the game is built as Godot scenes. You watch Godot open and the game being played; Claude checks the screenshots.
7. **Done gate:** Claude cannot say "done" until splash, sound, pause, three screen sizes, asset list and review pass.
8. **Publish (optional):** store graphics, texts, privacy page, signed builds. You keep keys, payments and the final submit.

If Claude starts writing code before you approved the summary, or says "tested" without opening Godot, stop it and say "follow the factory order".

## Needs

macOS, Godot 4.x, ffmpeg, python3, node, git. The `doctor` skill checks all of it.
Android/iOS export, ads, generated art and pixel art are optional extras; see [docs/REFERENCE.md](docs/REFERENCE.md).

## More

- [docs/REFERENCE.md](docs/REFERENCE.md): every script, skill and template, commands, the Definition of Done gate, credit limit
- `lessons/`: every mistake that reached a user, each with an enforcing rule
- `docs/decisions/`: why each tool was chosen, with measured results

## Honest limits

- Sound and feel must be confirmed on a real device; desktop playtests cannot hear audio routing or show hitches.
- Difficulty tools measure shortcut strategies and prove solvability, not whether a level is fun.
- Only macOS and Godot 4.7 are tested; Android was verified on an emulator (Gradle build with AdMob and Firebase, logcat), not on a real Android phone.
- Firebase projects have a per-account quota: games may share one project (one app per game); the monetization module README lists the trade-offs.
- Live ads need a store listing in AdMob and its review; until then serving is limited. Debug builds never request live ads.

## License

MIT for the plugin code. Third-party assets keep their own licenses, listed in each game's `ASSETS.md`.
