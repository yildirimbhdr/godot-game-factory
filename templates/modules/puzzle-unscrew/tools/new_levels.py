#!/usr/bin/env python3
"""Generate candidate variants for new levels, probe them in Godot, append the first passing variant of each to game/levels.gd.

  new_levels.py            probe + append every level in NEW that is not in levels.gd yet
Variants = partition seed x bar pattern x piece size. Colour deals are searched afterwards with apply_design.py.
"""
import json, re, subprocess, sys
NEW = [
 # name, tray, jars_visible, colors, target_greedy, mask
 ("Apple", 4, 3, 4, 0.20, ["....#....", ".##.#.##.", "#########", "#########", "#########", "#########", ".#######.", "..##.##.."]),
 ("Ghost", 3, 2, 5, 0.08, ["..#####..", ".#######.", "#########", "##.###.##", "#########", "#########", "#########", "##.#.#.##"]),
 ("Moon", 3, 2, 5, 0.08, ["..####...", ".####....", "####.....", "####.....", "####.....", ".####....", "..####..."]),
 ("Cloud", 4, 2, 6, 0.10, ["...###...", ".#######.", "#########", "#########", ".#######."]),
 ("Umbrella", 3, 2, 5, 0.07, ["..#####..", ".#######.", "#########", "#########", "....#....", "....#....", "....#....", "...##...."]),
 ("Bell", 3, 2, 5, 0.06, ["....#....", "...###...", "..#####..", "..#####..", ".#######.", ".#######.", "#########", "#########", "....#...."]),
 ("Anchor", 3, 2, 6, 0.06, ["....#....", "...###...", "....#....", ".#######.", "....#....", "....#....", "#...#...#", "##..#..##", ".#######.", "..#####.."]),
 ("Snowman", 2, 3, 4, 0.10, ["...###...", "..#####...", "...###...", "..#####..", ".#######.", ".#######.", ".#######.", "..#####.."]),
 ("Robot", 3, 2, 6, 0.05, ["....#....", "...###...", ".#######.", ".##.#.##.", ".#######.", ".#######.", "#.#####.#", "#.#####.#", "..##.##..", "..##.##.."]),
 ("Lighthouse", 3, 1, 5, 0.06, ["...###...", "..#####..", "...###...", "...###...", "..#####..", "..#####..", "..#####..", ".#######.", "#########"]),
 ("Butterfly", 3, 2, 6, 0.05, ["##.....##", "####.####", "#########", ".#######.", "#########", "####.####", "##.....##"]),
 ("Tulip", 4, 2, 6, 0.06, ["#..#.#..#", "##.###.##", "#########", ".#######.", "..#####..", "....#....", "....#....", "...##...."]),
 ("Trophy", 3, 2, 6, 0.04, ["#########", "#.#####.#", ".#######.", "..#####..", "...###...", "....#....", "...###...", "..#####.."]),
 ("Gem", 3, 1, 6, 0.04, ["..#####..", ".#######.", "#########", "#########", ".#######.", "..#####..", "...###...", "....#...."]),
]
src = open("game/levels.gd").read()
todo = [n for n in NEW if f'"name": "{n[0]}"' not in src]
def bars_for(pattern, R):
    h = lambda p, y, w=0.9: [p, 0.5, y, 8.5, y, w]
    v = lambda p, x, w=0.8: [p, x, 0.5, x, R - 0.5, w]
    d1 = lambda p, w=0.8: [p, 0.5, 0.5, 8.5, R - 0.5, w]
    d2 = lambda p, w=0.8: [p, 8.5, 0.5, 0.5, R - 0.5, w]
    return [
        [h(1, round(R * 0.4 * 2) / 2), v(2, 4.5)],
        [h(1, round(R * 0.3 * 2) / 2), h(1, round(R * 0.7 * 2) / 2), d1(2)],
        [d1(1), d2(2)],
        [v(1, 2.5, 0.9), v(1, 6.5, 0.9), h(2, round(R * 0.5 * 2) / 2, 0.8)],
        [h(1, round(R * 0.5 * 2) / 2), d1(2), d2(2)],
    ][pattern]
cands, meta = [], {}
for name, tray, jv, colors, tg, mask in todo:
    R = len(mask)
    for pattern in range(5):
        for size in ([4, 6], [3, 5], [4, 7]):
            for seed in range(1, 9):
                cid = f"{name}|{pattern}|{size[0]}-{size[1]}|{seed}"
                lv = {"name": name, "mask": mask, "seed": seed, "piece_size": size, "colors": colors, "bars": bars_for(pattern, R),
                      "tray": tray, "jars_visible": jv, "deep_first": True, "color_seed": seed}
                cands.append({"id": cid, "level": lv}); meta[cid] = (name, tray, jv, colors, tg, mask, pattern, size, seed)
json.dump(cands, open("tools/candidates.json", "w"))
out = subprocess.run(["godot", "--headless", "--path", ".", "-s", "tools/probe_levels.gd"], capture_output=True, text=True).stdout
passed = {}
for line in out.splitlines():
    m = re.match(r"(\S+) OK ", line)
    if m:
        cid = m.group(1); passed.setdefault(cid.split("|")[0], []).append(cid)
code = ""
for name, tray, jv, colors, tg, mask, *_ in todo:
    ids = passed.get(name, [])
    print(name, len(ids), "passing variants")
    if not ids:
        continue
    cid = ids[0]
    _, tray, jv, colors, tg, mask, pattern, size, seed = meta[cid]
    R = len(mask)
    bars = bars_for(pattern, R)
    bar_txt = "".join(f'\t\t\t{{"plane": {b[0]}, "a": Vector2({b[1]}, {b[2]}), "b": Vector2({b[3]}, {b[4]}), "w": {b[5]}}},\n' for b in bars)
    mask_txt = "".join(f'\t\t\t"{r}",\n' for r in mask)
    code += (f'\t{{ # {name.lower()}\n\t\t"name": "{name}", "color_seed": 1, "target_greedy": {tg}, "max_greedy": {min(0.98, tg + 0.12):.2f}, '
             f'"deep_first": true, "jars_visible": {jv}, "tray": {tray}, "colors": {colors}, "seed": {seed}, "piece_size": [{size[0]}, {size[1]}],\n'
             f'\t\t"mask": [\n{mask_txt}\t\t],\n\t\t"bars": [\n{bar_txt}\t\t],\n\t}},\n')
if code:
    i = src.rindex("\n]\n\n\nstatic func validate") if "static func validate" in src else src.rindex("\n]")
    src = src[:i + 1] + code + src[i + 1:]
    open("game/levels.gd", "w").write(src)
    print("appended", code.count('"name"'), "levels")
