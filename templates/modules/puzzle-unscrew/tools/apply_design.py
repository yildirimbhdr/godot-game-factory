#!/usr/bin/env python3
"""Run tools/design_levels.gd and write the chosen color_seed of every level into game/levels.gd."""
import re, subprocess, sys
out = subprocess.run(["godot", "--headless", "--path", ".", "-s", "tools/design_levels.gd"] + (["--", sys.argv[1]] if len(sys.argv) > 1 else []), capture_output=True, text=True).stdout
src = open("game/levels.gd").read()
for m in re.finditer(r"^level \d+ (\S+)\s+color_seed=(-?\d+)", out, re.M):
    src, n = re.subn(r'("name": "%s", "color_seed": )\d+' % m.group(1), r"\g<1>%s" % m.group(2), src, count=1)
    if n == 0:
        print("no color_seed field for", m.group(1))
open("game/levels.gd", "w").write(src)
print("\n".join(l for l in out.splitlines() if l.startswith("level")))
