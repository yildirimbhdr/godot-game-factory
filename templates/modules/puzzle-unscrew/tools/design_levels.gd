extends SceneTree
## godot --headless --path . -s tools/design_levels.gd [-- <level number>]
## Tries many colour deals per level and keeps the one whose GREEDY win rate (tap what the visible jars ask for)
## is closest to the level's `target_greedy`, then confirms by search that it can still be won.
## Prints the colour seed; tools/apply_design.py writes it into levels.gd.

func _init() -> void:
	var only := -1
	for a in OS.get_cmdline_user_args():
		only = int(a)
	for i in Levels.DATA.size():
		if only > 0 and i + 1 != only:
			continue
		var lv: Dictionary = Levels.DATA[i].duplicate()
		var data := Figure.build(lv)
		var an := Figure.analyze(data)
		var target: float = lv.get("target_greedy", 0.3)
		var rng := RandomNumberGenerator.new()
		rng.seed = 77
		var scored: Array = []
		for color_seed in range(1, 301):
			Figure.recolor(data, color_seed, an)
			var greedy := 0
			for _t in 120:
				if Figure.simulate(data, an, rng, Figure.GREEDY)["win"]:
					greedy += 1
			scored.append([absf(greedy / 120.0 - target), color_seed, greedy / 1.2])
		scored.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
		var picked := -1
		var line := ""
		for k in mini(25, scored.size()):
			Figure.recolor(data, scored[k][1], an)
			var solved: Dictionary = Figure.solve(data, an, 150000)
			if solved["solved"]:
				picked = scored[k][1]
				line = "greedy~%.0f%% solved in %d nodes" % [scored[k][2], solved["nodes"]]
				break
		print("level %d %-8s color_seed=%d %s (target greedy %.0f%%)" % [i + 1, lv["name"], picked, line, target * 100.0])
	quit(0)
