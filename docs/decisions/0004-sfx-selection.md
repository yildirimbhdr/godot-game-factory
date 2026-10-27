# 0004 – SFX source and defaults (2026-10-21)

Blind listening test by the user (the assistant cannot listen, so candidates are always auditioned by ear).

## Result
- pyfxr (sfxr model): rejected as the default. "Too artificial, electronic, shrill, distorted." Kept as an explicit retro style option only.
- Kenney CC0 packs (Interface Sounds, UI Audio, Music Jingles): accepted. Licence verified on each pack page and in the packaged `License.txt` (CC0, commercial use allowed, credit optional).
- Rejected inside Kenney: `select_*`, "Hit jingles" (muffled).

## Template defaults (`templates/godot-base/assets/audio/sfx.spec.json`)
| sound | source |
|---|---|
| ui_click | interface-sounds `Audio/click_001.ogg` |
| score | interface-sounds `Audio/confirmation_001.ogg` |
| game_over | music-jingles `Pizzicato jingles/jingles_PIZZI05.ogg` |

## Liked alternatives (use to vary games so they do not all sound the same)
- ui_click: interface-sounds `click_002..005`, ui-audio `click1..3`
- score: interface-sounds `confirmation_001..004`, `pluck_002`, `glass_001`; music-jingles Steel jingles `STEEL00`, `STEEL04`
- game_over: interface-sounds `error_002`, `drop_002`; music-jingles `PIZZI05`

## Pipeline
`scripts/sfx.sh build <project>` reads the spec, fetches packs on demand (`scripts/kenney.py`, refuses packs whose page does not state CC0),
normalizes to -6 dBFS, writes WAVs, a lock file and the generated block of `ASSETS.md`.

## If this is not enough
Paid options researched (prices from official pages, unverified licensing): ElevenLabs SFX (Starter $6/mo, 150 generations),
Ludo MCP (Pro $35/mo billed yearly for API/MCP, SFX 2 credits). Read the current terms before buying.
