# 0006 – UI themes from recipes (2026-10-21)

Problem: the neutral template theme is flat grey. Games must not all look alike, and a game needs its own look.

Decision: a UI theme is built from a small JSON recipe (`data/themes/*.json`) on Kenney CC0 packs by `scripts/build_theme.py`
(9-slice buttons and panels, font, palette, backdrop). Four recipes exist: casual-blue, casual-green, fantasy-brown, scifi-blue.
Choosing the look for a game is choosing or writing a recipe; the template scenes do not change.

What went wrong while building it (each is now a lesson): buttons unreadable because text and button colors matched
(recipes have a separate `button_text` color); two textures with the same file name in different color folders overwrote each other
(lesson 0005); upscaled textures had a dark halo (color and alpha are now scaled separately); screenshots showed the wrong moment (lesson 0006).

Limits: theme recipes cover generic UI only. Game-specific art (characters, items, icons) needs generated or hand-made assets, see 0005.
