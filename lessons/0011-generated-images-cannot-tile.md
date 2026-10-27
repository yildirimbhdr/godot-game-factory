---
id: 0011
title: AI-generated pieces cannot form a jigsaw
area: assets
severity: major
status: encoded
---

**What happened:** plate images from the image API were separate shapes; pieces that must fit each other, cross at exact angles and collide correctly need exact geometry.
**Rule:** puzzle pieces are polygons built in code and drawn in the game's style; image generation is for icons, characters, jars, backgrounds and other free-standing art. Decide this in the asset list, not after the first build.
**Encoded in:** `skills/physics-puzzle-design` section 2, `skills/asset-pipeline`, `templates/modules/puzzle-unscrew/figure.gd`
