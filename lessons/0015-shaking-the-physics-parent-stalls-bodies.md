---
id: 0015
title: Screen shake on the physics parent stalled falling bodies
area: juice
severity: major
status: encoded
---

**What happened:** the juice added in round 2 shook the `World` node that parents all RigidBody2D pieces, and built a new GradientTexture2D / Gradient for every burst. On the iPhone SE falling pieces paused mid-fall and then dropped, exactly when a jar-complete or release effect fired. The user noticed it by playing fast.
**Rule:** shake with a Camera2D offset (never move the parent of bodies), cache effect resources once per scene, and compute per-frame cover checks only when something changed. Verify smoothness on the real device after adding effects; headless playtests run at a fixed step and cannot show hitches.
**Encoded in:** `templates/modules/common/game_fx.gd` (camera shake, cached resources), `skills/physics-puzzle-design` section 7
