---
id: 0014
title: A long design-tool loop hit the tool timeout
area: workflow
severity: minor
status: encoded
---

**What happened:** looping `apply_design.py` (80 colour seeds x 8 levels) over several partition seeds ran past the 120 s limit and was moved to the background, stalling work.
**Rule:** make the design tool accept a level number (or `--only`) so a loop touches one level; run long loops with `run_in_background` and keep working on other files; never edit the file the tool rewrites meanwhile.
**Encoded in:** `tools/design_levels.gd` and `apply_design.py` take a level number; run long loops in the background
