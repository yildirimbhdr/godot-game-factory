# 0008 - UI themes are a base, adapted per game (2026-10-21, user)

User: the four Kenney recipes (casual-blue, casual-green, fantasy-brown, scifi-blue) are all good, but using one unchanged would make every game look alike.

Decision:
- A recipe is the structural base (9-slice panels/buttons, layout, fonts). Per game, recolor it to the game's palette and replace/add icons and ornaments made from the game's concept, generated with `genart.py` (Gemini) in the approved anchor's style.
- No single global theme choice is needed; the art-direction brief picks the base recipe and lists the icon set in the asset manifest.
- Generated icons count against the credit limit (see 0007).

## Anchor approved (2026-10-21)
`audition-flat/anchor/screw_pastel.png` approved by the user (mint/pink/lavender, thick purple outline). A 5-recolor set made with `--ref` stays consistent (`audition-flat/set/`, contact sheet `audition-flat/contact_sheet.png`); spent ~$0.48 of the $3 limit.

## Pilot game started (2026-10-21)
Pilot = screw-unscrewing puzzle (`~/Desktop/games/screw-pilot/`, brief `ART_BRIEF.md`). The user supplied a screenshot of an existing game of the genre purely to explain the mechanic; rule: take the genre rules, never the look, layout, names or UI. Plugin lesson to encode: when the user gives a reference image, extract mechanics only and write what will differ.

## Unwind: physics and depth planes (2026-10-21, user)
User requirement for the pilot: real physics. Remove one of two screws and the plate pivots on the other and swings down; with no screws it falls and hits other plates. Implementation plan: RigidBody2D plates, PinJoint2D per screw to a static anchor, two depth planes (collision layers), a screw is tappable only when no plate in front covers it. Brief updated (`screw-pilot/ART_BRIEF.md`). Jar anchor candidates in `audition-unwind/anchor/` (jar_2 recommended).

## Unwind assets, round 1 (2026-10-21)
Jar anchor jar_2 approved. Generated 5 jar recolors + 6 plate shapes (plank, bar, square, circle, triangle, arch) in `audition-unwind/`, contact sheet `audition-unwind/contact_sheet.png`. Known flaws: coral jar face is lavender (weak color identity), pink square has a mint/lavender edge artifact, arch has a double edge. Spent ~$1.52 of $3.
Plugin note: `genart.py --size` fits into a square canvas; for plates with a strong aspect ratio the game should trim to the alpha bbox (or add a non-square option).
