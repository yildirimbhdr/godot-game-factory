# 0018 - Prism Path: second game through the 0.4 workflow (2026-10-22)

A mirror-and-beam puzzle made with the 0.4 workflow (ideation, brief, anchor approval, template copy, Godot-only build, visible tests).

## What worked
- Ideas from 16 candidates across families; the user picked a puzzle that needs no external data (a word game was dropped for lack of a clean Turkish word list).
- Anchor first: one board, approved before any other work.
- Level factory + solver + shortcut bot gave 60 levels with a measured curve; sharing mirrors between paths was the change that made later worlds hard.
- Icon-only pause/result/settings screens via `GlyphButton` without any icon files.

## What it changed in the plugin
- Modules `light-puzzle`, `level-grid`; `StarRow`, `GlyphButton`, `Backdrop` in `common`; icon screens and stars in the base template.
- Lessons 0031 (variable font stalls Movie Maker recording; `build_theme.py` now refuses variable fonts) and 0032 (timed scenarios hide skipped steps).
- Theme recipe `prism-night` with a static Nunito SemiBold (Turkish glyphs verified).

## Still open for this game
Real-device checks (sound with the silent switch, smoothness) and the store release.

## Design pass (same day)
- Juice in code first (free), then Gemini for what code cannot do: app icon (2 candidates, the user's pick left to the recommendation), six world backdrops
  from one approved anchor, a keyed logo that matches the icon. 9 images, about 0.7 USD estimated, inside the user-set limit (raised twice by the user's word;
  an ambiguous "2" was read conservatively and confirmed).
- The anchor-first rule held: one backdrop was approved before the other five were generated from it as a style reference.
- Backdrops are dimmed in code (`Backdrop.dim`) so the board stays readable.

## Second design round (the user: "buttons too solid, use icons, stars and animations are flat")
- Solid Kenney buttons replaced by a glass style in `build_theme.py` (`"glass"` recipes); Righteous (static, full Turkish) after Fredoka and Lilita One failed the glyph check.
- Menu, HUD, pause, settings and result screens are icon-first; the play button is the one glowing, pulsing control.
- Stars: Gemini crystal star sprite (2 candidates, the faceted one fits the gem identity), elastic pop, turning rays, sparkle burst, rising pitch.
- Board: facet-shaded crystals, glossy lamps, mirror glow, cell sheen. Beams: only the light leaving a flipped mirror re-forms, quickly, with a bright travelling head.
