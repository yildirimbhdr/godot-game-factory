---
id: 0037
title: Reachability results did not map back onto the level because the analysis rows were cropped
area: workflow
severity: minor
status: encoded
---

**What happened:** The generator analysed a cropped copy of the level (rows trimmed to the used height) and then looked the results up with uncropped canvas coordinates; every lookup missed and all candidates were rejected.
**Root cause:** two coordinate systems for the same level.
**Rule:** an analysis pass over a generated level must use the same coordinates as the generator (no cropping or shifting until the very last step), or return the offset with the result.
**Encoded in:** `slide-buddies/tools/gen_levels.gd` (`_rows(..., crop := false)` for analysis).
