---
id: 0043
title: Store capture scenarios silently stayed on the level map: the tapped level node was locked
area: testing
severity: minor
status: encoded
---

**What happened:** `store_level4.json` set `level_unlocked` to 3 and tapped node index 3; the node was locked so nothing happened and the playtest only failed later with "no node in group game with method autoplay". Nodes off-screen on the scrolled map also cannot be tapped.
**Root cause:** `level_unlocked` is the number of open levels, not the last open index; the map scrolls to the current level, so only nodes near it are visible.
**Rule:** For a store frame of level N (1-based) set `level_unlocked` to N and tap `level_node` index N-1; levels far above the current one are not reachable, so stage each level with its own unlocked count. Also keep the window awake (`caffeinate -d -u`) and re-run when the recorder reports "truncated" (lessons 0008, 0033).
**Encoded in:** `skills/store-release/SKILL.md` step 3
