extends SceneTree
## godot --headless --path . -s tools/probe_levels.gd
## Reads tools/candidates.json ([{id, level}] with bars as [plane, ax, ay, bx, by, w]) and prints which candidates
## pass the geometry rules (>=2 screws per piece, spacing, board area). Used to auto-tune new levels.

func _init() -> void:
	var f := FileAccess.open("res://tools/candidates.json", FileAccess.READ)
	var cands: Array = JSON.parse_string(f.get_as_text())
	for c in cands:
		var lv: Dictionary = c["level"].duplicate(true)
		var bars := []
		for b in lv.get("bars", []):
			bars.append({"plane": int(b[0]), "a": Vector2(b[1], b[2]), "b": Vector2(b[3], b[4]), "w": b[5]})
		lv["bars"] = bars
		var data := Figure.build(lv)
		var why := ""
		var total := 0
		for p in data["pieces"]:
			total += p["screws"].size()
			if p["screws"].size() < 2:
				why = "piece with <2 screws"
		for pa in data["pieces"].size():
			for sa in data["pieces"][pa]["screws"]:
				for pb in range(pa, data["pieces"].size()):
					for sb in data["pieces"][pb]["screws"]:
						if sa != sb and sa.distance_to(sb) < 74.0:
							why = "screws too close"
		var b: Rect2 = data["bounds"]
		if b.position.x < 40 or b.end.x > 1040 or b.position.y < 520 or b.end.y > 1640:
			why = "outside board area"
		if total < 15 or total > 36:
			why = "screw count %d" % total
		var an := Figure.analyze(data)
		var share := Figure.open_share(an)
		if why == "" and (share > 0.68 or share < 0.25):
			why = "open share %.0f%%" % (share * 100.0)
		print("%s %s screws=%d open=%.0f%% %s" % [c["id"], "OK" if why == "" else "FAIL", total, share * 100.0, why])
	quit(0)
