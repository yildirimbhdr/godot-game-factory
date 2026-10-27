---
name: asset-pipeline
description: Get art, UI themes, sound effects and music for a Godot game with licenses recorded. Use when a game needs any asset, when choosing an art direction, or before generating or downloading something.
---

# Asset pipeline

Every external asset ends up in `ASSETS.md` with source, author, license and date. Only CC0 or licenses that allow commercial use.
The assistant cannot hear: always give the user named candidates to audition (a folder with clearly named files) before fixing a sound choice.
See `docs/decisions/0004-sfx-selection.md` for sounds already approved by ear.

## UI theme (generic, per art direction)
`python3 scripts/build_theme.py <game> data/themes/<recipe>.json` builds a 9-slice Godot theme from Kenney CC0 packs
(recipes: casual-blue, casual-green, fantasy-brown, scifi-blue; add new recipes as JSON). Check a rendered screenshot after every build.
Packs are downloaded by `scripts/kenney.py` only if the Kenney page states CC0.
**Never ship a recipe as-is** (decision 0008): pick the closest recipe as the *base*, then adapt it to the game: palette/accent colors in the recipe, and game-specific icons (settings, pause, score, currency, buttons' glyphs), panel ornaments and logo generated with `scripts/genart.py` from the approved anchor (`--ref`). Two games must not end up with the same-looking UI.

### Glass style and fonts (Prism Path, 2026-10-22)
- A recipe with a `"glass"` block ({"fill", "border", "radius", "glow"}) builds translucent buttons with a bright rim and soft glow instead of Kenney's solid
  textured buttons (`data/themes/prism-glass.json`); the panel can be `{"flat": {"bg": "#10143ADD", ...}}` (8-digit hex = alpha). Prefer it when the user finds the
  textured buttons "solid".
- Prefer icons to words on controls: `GlyphButton`/`GlyphIcon` (modules/common) draw undo, restart, hint, home, play, pause, next, gear, power, levels, back,
  vibrate, note, speaker and globe in code; the button text stays for tests but is not drawn.
- **Fonts must be static and cover `ĞÜŞİÖÇığüşöç`** (lesson 0023, 0031). Checked: Righteous (static, complete), Nunito / Baloo 2 / Rubik (variable: make a static instance
  with fontTools.varLib.instancer first), **Fredoka and Lilita One lack Ğ Ş İ ğ ş**. Verify with fontTools before choosing; a static instance of Nunito "SemiBold" rendered light, look at it.
- Reward art that code cannot make convincingly (a star, a logo, backdrops) is the right use of the image budget; code-drawn glyphs and facets cover the rest.

## Sound effects (required)
`assets/audio/sfx.spec.json` + `scripts/sfx.sh build <game>`. Default source: Kenney CC0 packs (`interface-sounds`, `ui-audio`, `music-jingles`).
`pyfxr` (retro synth) only when the game's style is deliberately retro. Vary choices between games so they do not all sound the same.

## Game-specific SFX set (do this per game)
List the game's own events in the spec, not just click/score/game_over. Puzzle-game set used by Unwind: `unscrew` (action, pitch-shift upward on combos), `land`, `jar_done`, `thud` (impact-sounds pack for physical pieces), `mistake`, `star` (rises per star), `win`, `game_over`. Put 3-4 candidates per event into `~/Desktop/games/audition-<game>-sfx/` (ffmpeg to wav, letters A-D, README), wire A as default so the game is never silent, and let the user swap by letter. Stay inside the user's liked sounds (audio taste memory) and CC0 packs.

## Music (optional)
CC0 loops come from OpenGameArt: open the page, read the license field, record author and page URL (`music.sh add`). Verified CC0 used so far: MintoDog "Cozy Puzzle In-Game 2", OwlishMedia "Happy Clappy Loop", Ruskerdax "Happy Vibes". Avoid CC-BY tracks unless in-game credit is added. Use `play_music("menu")` for menu/map and `play_music("gameplay")` in game.
`scripts/music.sh add <game> <name> <file-or-url> --author A --license CC0 --source-url URL`. Verify the license on the source page first.

## App icon
Generate with `genart.py --keep-bg --aspect 1:1` (full-bleed 1024x1024, no transparency, no text, one bold subject readable at 60 px) from the approved anchor; show 2 candidates; set `application/config/icon`. Never ship the template icon.

## Game-specific art (characters, items, icons made for this game's theme)
Generic packs do not cover this. Process:
1. **Style bible** in `GDD.md`: palette (hex), line/shading style, perspective, size grid, 2-3 reference images made first and reused.
2. **Asset manifest** (`assets.manifest.json`): one entry per asset with name, purpose, size, prompt that always includes the style bible.
3. Generate through a provider, **look at every result**, reject and re-prompt, keep the accepted file and the prompt that made it.
4. Post-process (transparent background, trim, downscale to the size grid), import into `assets/`, record in `ASSETS.md`.
Providers (decision record: `docs/decisions/0005-ai-asset-generation-research.md`): pixel-art games use PixelLab (MCP/API);
other styles use a direct image API through our own script. Higgsfield MCP is not used for asset generation (credit markup).
Check the provider's terms for commercial use before shipping anything it generated.

## UI font
Use one pixel font that contains the glyphs of every shipped language; do not patch a missing-glyph font with a fallback (sizes and weights never match). Pixelify Sans (OFL) covers Turkish. Check ğ ş ı İ in a screenshot with `GF_LANG=tr` before shipping (lessons 0038, 0056).
