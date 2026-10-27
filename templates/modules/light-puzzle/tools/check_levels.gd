extends SceneTree
## godot --headless --path . -s tools/check_levels.gd
## Every level must be solvable and not solved at the start; prints par (fewest taps).

func _initialize() -> void:
	var bad := 0
	for i in Levels.DATA.size():
		var lv: Dictionary = Levels.DATA[i]
		var start := Optics.trace(lv, (lv.mirrors as Array).map(func(m: Dictionary) -> int: return int(m.kind)))
		var sol := Optics.solve(lv)
		var ok := int(sol.par) > 0 and not Optics.is_solved(start.open)
		print("level %d %s par=%d (declared %s) %s" % [i + 1, lv.get("name", ""), sol.par, lv.get("par", "?"), "ok" if ok else "BAD"])
		if not ok:
			bad += 1
	quit(1 if bad > 0 else 0)
