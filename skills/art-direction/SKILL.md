---
name: art-direction
description: First step of a new game. Turns a game idea into a visual brief, a style anchor the user approves, and a complete asset set before any gameplay code. Use when the user asks to make a game, names a new game idea, or asks for assets or a look for a game.
---

# Art direction (assets first)

The user wants the asset set before the game is built. Do not start gameplay code until the set is approved.
Fixed rule from `docs/decisions/0007-art-style-routing.md`: one style per game, and the style decides the asset source.

## Steps
1. **Brief.** Copy `brief-template.md` to the game's `GDD.md` (or `ART_BRIEF.md`) and fill it from the idea: style, palette (hex), perspective, line/shading, size grid, mood, asset list. Ask the user only for what the idea does not answer. Show the brief and wait for approval.
2. **Route by style.**
   - Pixel art: PixelLab MCP (`create_1_direction_object`, tilesets, characters). Costs generations; check `get_balance` first and say the cost before each call.
   - Flat / clean 2D: Kenney CC0 packs first (`scripts/kenney.py`); anything game-specific goes through the image API script (`scripts/genart.py`, needs `GEMINI_API_KEY` and Pillow).
3. **Style anchor.** Generate ONE asset first (the most representative), put it in `~/Desktop/games/audition-<game>/anchor/`, open the folder for the user, and wait for approval or changes. Never batch-generate before the anchor is approved.
4. **Asset manifest.** `assets.manifest.json`: per asset name, purpose, size, prompt (always includes the style bible and the anchor as a reference), status.
5. **Generate the set** in the same style, using the anchor as reference. Look at every result yourself: transparent background, size, silhouette readable at phone size, same palette and line weight as the anchor. Reject and re-prompt bad ones; keep accepted file and its prompt.
6. **Post-process:** remove background, trim, resize to the size grid, name files by the manifest.
7. **Audition folder** with a contact sheet (all assets on a dark and a light background) for the user, then wait for approval. After approval import into `assets/` and record every file in `ASSETS.md` (source, tool, prompt, license, date).
8. Record user approvals and rejections in `docs/decisions` the same session.

## Reference screenshots and theme (hard rules)
- When the user shares a reference game, run the checklist in `physics-puzzle-design` section 1 (or the equivalent for other genres) and put structure, density, layering and figure plan into the brief. See lesson 0010.
- The UI theme is not done until it has its own font, tinted button palette and a backdrop with faint game icons (lesson 0012, decision 0008).
- Free-standing art comes from `genart.py`; anything that must fit together exactly (puzzle pieces, tiles) is built in code (lesson 0011).

## Credit limit (hard rule)
- Paid image calls always run under a user-set cap. Before the first generation run `scripts/genart.py --status`; if the limit is NOT SET, ask the user for an amount and set it with `--set-limit`. Never pick or raise the limit yourself.
- The script refuses to run without a limit and when the next image would exceed it. When refused, stop, report spent/limit and ask the user. Do not work around it (other models, other keys, direct curl).
- Say the remaining budget when starting a batch; prefer 1-2 anchor candidates over many. Spend is an estimate; the real bill is at https://ai.dev/spend.

## Mood follows the game
Fun/casual games get colorful, friendly looks (pastel candy palette, thick rounded outline, glossy highlight, slightly chubby shapes) unless the brief says otherwise. Put palette hex values and outline color into the prompt. Describe object parts, not just the name (a bare "screw" returned a nut).

## Done when
Brief approved, anchor approved, full set approved, `ASSETS.md` complete, UI theme chosen to match the style (see `asset-pipeline`).
