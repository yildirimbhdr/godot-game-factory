# 0007 – Art style is chosen per game; asset source follows the style (2026-10-21)

Decision (user): the plugin must not be pixel-art only. Claude picks the art style for each game in the design brief (with the user's approval), and the asset source follows from that style.

| Style | Asset source | Notes |
|---|---|---|
| Pixel art | PixelLab MCP | Characters, objects, tilesets, UI, fonts, VFX; trial pending (screws set) |
| Non-pixel (flat vector, painterly, clean 2D) | Kenney CC0 packs first, then a general image API (Gemini direct is the leading candidate, see 0005) | Needs background removal, trim and a shared style anchor per game |

Rules:
- The style is written into the game's brief and `ASSETS.md` before any asset is generated; one game uses one style.
- Do not mix PixelLab output with non-pixel assets in the same game.
- The general image route is not set up yet; build it when the first non-pixel game needs it, and record it here.

## PixelLab trial result (2026-10-21)
- One 64x64 top-down screw (`create_1_direction_object`) cost 10 of the 40 trial generations and returned 16 near-identical candidates; quality was clean and consistent (candidates saved in `~/Desktop/games/audition-pixellab/screw-trial/`).
- User verdict: too small and too pixel-like for the flat asset sets they want as the main use. Kept as the pixel-art route only. Review dismissed, nothing imported.
- Budget note: a real game needs far more than the trial allows (about 3 more objects); the paid plan would be required.
- Next: the flat/clean 2D route (general image API) is the main need and should be trialled next.

## Flat route set up (2026-10-21)
- `scripts/genart.py` written: Gemini image API (`gemini-3.1-flash-image`), magenta key-out, trim, square fit, `--ref` for the style anchor. Needs Pillow (user approved install) and `GEMINI_API_KEY`.
- Free tier has no image quota (429 on all image models); the user added prepaid credit to the key's project, after which it worked.
- First test: a "screw" prompt returned a nut; naming shape and orientation explicitly fixed it. Lesson: describe the object's parts, not just its name.
- Anchor candidates in `~/Desktop/games/audition-flat/anchor/` (screw.png = nut, screw2.png = screw), waiting for the user's verdict.

## Credit limit and fun mood (2026-10-21, user)
- User rule: image generation must have a credit limit. `genart.py` has a mandatory `--set-limit USD`, a ledger at `~/.game-factory/genart_ledger.json`, conservative per-image estimates, and refuses when no limit is set or the cap would be exceeded. Only the user sets/raises it. First limit: $3.
- User wants fun games to look colorful/pastel, not plain steel gray. Pastel anchor candidate: `audition-flat/anchor/screw_pastel.png` (mint/pink/lavender, thick purple outline).
