extends SceneTree
## godot --headless --path . -s tools/check_levels.gd
## Builds every level and checks the design rules.
##   random = win rate of a player who taps anything legal
##   greedy = win rate of the player who only taps what the visible jars ask for (the human shortcut)
##   solved = a winning order exists (depth-first search)
## From level 2 on, greedy must stay under the level's max_greedy: looking at the jars must not be enough.

func _init() -> void:
	var failed := false
	for i in Levels.DATA.size():
		var lv: Dictionary = Levels.DATA[i]
		var data := Figure.build(lv)
		var errors := PackedStringArray()
		var total := 0
		var counts := {}
		for p in data["pieces"]:
			if p["screws"].size() < 2:
				errors.append("a piece has fewer than 2 screws (plane %d, %d cells)" % [p["plane"], p["cells"].size()])
			total += p["screws"].size()
			for c in p["screw_colors"]:
				counts[c] = counts.get(c, 0) + 1
		for pa in data["pieces"].size():
			for sa in data["pieces"][pa]["screws"]:
				for pb in range(pa, data["pieces"].size()):
					for sb in data["pieces"][pb]["screws"]:
						if sa != sb and sa.distance_to(sb) < 74.0:
							errors.append("screws %d px apart" % sa.distance_to(sb))
		for c in counts:
			if counts[c] % 3 != 0:
				errors.append("colour %s: %d screws" % [c, counts[c]])
		var b: Rect2 = data["bounds"]
		if b.position.x < 40 or b.end.x > 1040 or b.position.y < 520 or b.end.y > 1640:
			errors.append("figure leaves the board area: %s" % b)
		var an := Figure.analyze(data)
		var rng := RandomNumberGenerator.new()
		rng.seed = 123
		var rnd := 0
		var greedy := 0
		for _t in 400:
			if Figure.simulate(data, an, rng, Figure.RANDOM)["win"]:
				rnd += 1
			if Figure.simulate(data, an, rng, Figure.GREEDY)["win"]:
				greedy += 1
		var solved: Dictionary = Figure.solve(data, an)
		var share := Figure.open_share(an)
		if not solved["solved"]:
			errors.append("no winning order found (%d nodes)" % solved["nodes"])
		if i > 0 and greedy / 400.0 > lv.get("max_greedy", 0.5):
			errors.append("looking at the jars is enough: greedy wins %.0f%%" % (greedy / 4.0))
		if i > 0 and share > 0.72:
			errors.append("%.0f%% of screws open at the start" % (share * 100.0))
		print("level %d %-8s pieces=%2d screws=%2d open=%2.0f%% random=%3.0f%% greedy=%3.0f%% solved=%s(%d) %s" % [
			i + 1, lv["name"], data["pieces"].size(), total, share * 100.0, rnd / 4.0, greedy / 4.0,
			solved["solved"], solved["nodes"], "OK" if errors.is_empty() else str(errors)])
		failed = failed or not errors.is_empty()
	quit(1 if failed else 0)
