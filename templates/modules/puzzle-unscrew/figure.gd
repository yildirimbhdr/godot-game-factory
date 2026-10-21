class_name Figure
## Turns a level Dictionary (see levels.gd) into piece polygons, screw positions and colours.
## Pure data: no nodes. Coordinates are world pixels with the figure centred at (540, CENTER_Y).

const CENTER_Y := 1060.0
const GAP := 5.0
const ROUND := 12.0
const MIN_SCREW_DIST := 104.0  # any two screws, even on different pieces; heads are 68 px wide
const TRAY_SIZE := 3
const VISIBLE_JARS := 3
enum {RANDOM, GREEDY, HEURISTIC}


static func build(level: Dictionary) -> Dictionary:
	var cell: float = level.get("cell", 100.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = level.get("seed", 1)
	var mask: Array = level.get("mask", [])
	var cols: int = mask[0].length() if not mask.is_empty() else level.get("cols", 9)
	var rows: int = mask.size() if not mask.is_empty() else level.get("rows", 10)
	var origin := Vector2(540.0 - cols * cell / 2.0, CENTER_Y - rows * cell / 2.0)
	var pieces: Array[Dictionary] = []

	if not mask.is_empty():
		var regions := _partition(mask, level.get("piece_size", [3, 5]), rng)
		for region in regions:
			pieces.append(_cell_piece(region, origin, cell))
		_color_pieces(pieces, regions)
	for bar in level.get("bars", []):
		pieces.append(_bar_piece(bar, origin, cell))
	var idx := 0
	for p in pieces:
		if not p.has("fill"):
			p["fill"] = Levels.PIECE_COLORS[(idx * 3 + 1) % Levels.PIECE_COLORS.size()]
		idx += 1

	_place_screws(pieces)
	_fix_screw_count(pieces, cell)
	var jars := _assign_colors(pieces, level.get("colors", 3), level.get("color_seed", level.get("seed", 1)))
	var bounds := Rect2()
	for i in pieces.size():
		var b := _bounds(pieces[i]["poly"])
		bounds = b if i == 0 else bounds.merge(b)
	var data := {"pieces": pieces, "jars": jars, "bounds": bounds, "colors": level.get("colors", 3),
		"jars_visible": level.get("jars_visible", VISIBLE_JARS), "deep_first": level.get("deep_first", false),
		"color_seed": level.get("color_seed", level.get("seed", 1)), "tray": level.get("tray", TRAY_SIZE)}
	if data["deep_first"]:
		data["jars"] = order_jars(data, analyze(data))
	return data


# --- pieces ---------------------------------------------------------------

static func _cell_piece(region: Array, origin: Vector2, cell: float) -> Dictionary:
	var poly := PackedVector2Array()
	for c: Vector2i in region:
		var o := origin + Vector2(c) * cell
		var sq := PackedVector2Array([o, o + Vector2(cell, 0), o + Vector2(cell, cell), o + Vector2(0, cell)])
		if poly.is_empty():
			poly = sq
		else:
			poly = _largest(Geometry2D.merge_polygons(poly, sq))
	poly = _round(poly)
	var centers: Array[Vector2] = []
	for c: Vector2i in region:
		var mid := origin + (Vector2(c) + Vector2(0.5, 0.5)) * cell
		centers.append(mid)
		for d in [Vector2i(1, 0), Vector2i(0, 1)]:   # also the spots between two cells of the same piece
			if region.has(c + d):
				centers.append(mid + Vector2(d) * cell / 2.0)
	var k := 2 if region.size() <= 4 else 3
	return {"poly": poly, "plane": 0, "k": k, "screws": PackedVector2Array(), "spare": centers, "cells": region}


static func _bar_piece(bar: Dictionary, origin: Vector2, cell: float) -> Dictionary:
	var a: Vector2 = origin + bar["a"] * cell
	var b: Vector2 = origin + bar["b"] * cell
	var half: float = bar.get("w", 0.9) * cell / 2.0 - GAP / 2.0
	var poly := _largest(Geometry2D.offset_polyline(PackedVector2Array([a, b]), half, Geometry2D.JOIN_ROUND, Geometry2D.END_ROUND))
	var length := a.distance_to(b) / cell
	var k := 2 if length <= 4.5 else 3
	var inset := half
	var dir := (b - a).normalized()
	var span := a.distance_to(b) - 2.0 * inset
	var spare: Array[Vector2] = []
	for i in 25:
		spare.append(a + dir * (inset + span * i / 24.0))
	return {"poly": poly, "plane": bar["plane"], "k": k, "screws": PackedVector2Array(), "spare": spare, "cells": []}


static func _round(poly: PackedVector2Array) -> PackedVector2Array:
	var inner := _largest(Geometry2D.offset_polygon(poly, -(GAP / 2.0 + ROUND), Geometry2D.JOIN_ROUND))
	return _largest(Geometry2D.offset_polygon(inner, ROUND, Geometry2D.JOIN_ROUND))


static func _largest(polys: Array) -> PackedVector2Array:
	var best := PackedVector2Array()
	var best_area := -1.0
	for p: PackedVector2Array in polys:
		var a := absf(_area(p))
		if a > best_area:
			best_area = a
			best = p
	return best


static func _area(pts: PackedVector2Array) -> float:
	var a := 0.0
	for i in pts.size():
		var p := pts[i]
		var q := pts[(i + 1) % pts.size()]
		a += p.x * q.y - q.x * p.y
	return a / 2.0


static func _bounds(poly: PackedVector2Array) -> Rect2:
	var r := Rect2(poly[0], Vector2.ZERO)
	for p in poly:
		r = r.expand(p)
	return r


## Farthest-point sampling: k points of `pts` that are far from each other.
static func _spread(pts: Array[Vector2], k: int) -> PackedVector2Array:
	var mean := Vector2.ZERO
	for p in pts:
		mean += p
	mean /= pts.size()
	var chosen: Array[Vector2] = []
	var first := pts[0]
	for p in pts:
		if p.distance_to(mean) > first.distance_to(mean):
			first = p
	chosen.append(first)
	while chosen.size() < mini(k, pts.size()):
		var best := pts[0]
		var best_d := -1.0
		for p in pts:
			var d := INF
			for c in chosen:
				d = minf(d, p.distance_to(c))
			if d > best_d:
				best_d = d
				best = p
		chosen.append(best)
	return PackedVector2Array(chosen)


# --- jigsaw split -----------------------------------------------------------

static func _partition(mask: Array, sizes: Array, rng: RandomNumberGenerator) -> Array:
	var owner := {}
	for y in mask.size():
		for x in mask[y].length():
			if mask[y][x] == "#":
				owner[Vector2i(x, y)] = -1
	var regions: Array = []
	var dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for y in mask.size():
		for x in mask[y].length():
			var seed_cell := Vector2i(x, y)
			if not owner.has(seed_cell) or owner[seed_cell] != -1:
				continue
			var region: Array = [seed_cell]
			owner[seed_cell] = regions.size()
			var target := rng.randi_range(sizes[0], sizes[1])
			while region.size() < target:
				var options: Array = []
				for c: Vector2i in region:
					for d: Vector2i in dirs:
						var n: Vector2i = c + d
						if owner.get(n, 0) == -1 and not options.has(n):
							options.append(n)
				if options.is_empty():
					break
				var pick: Vector2i = options[rng.randi() % options.size()]
				owner[pick] = regions.size()
				region.append(pick)
			regions.append(region)
	# fold one-cell leftovers into a neighbouring region
	for r in regions.duplicate():
		if r.size() >= 2:
			continue
		var c: Vector2i = r[0]
		var host: Array = []
		for d: Vector2i in dirs:
			for other in regions:
				if other != r and other.has(c + d):
					host = other
		if not host.is_empty():
			host.append(c)
			regions.erase(r)
	return regions


static func _color_pieces(pieces: Array[Dictionary], regions: Array) -> void:
	var cell_owner := {}
	for i in regions.size():
		for c: Vector2i in regions[i]:
			cell_owner[c] = i
	for i in pieces.size():
		var used := {}
		for c: Vector2i in regions[i]:
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var o: int = cell_owner.get(c + d, -1)
				if o >= 0 and o != i and o < i:
					used[pieces[o]["fill_idx"]] = true
		var pick := 0
		while used.has(pick):
			pick += 1
		pieces[i]["fill_idx"] = pick
		pieces[i]["fill"] = Levels.PIECE_COLORS[pick % Levels.PIECE_COLORS.size()]


# --- screws -----------------------------------------------------------------

## Re-deal the colours of an existing figure (the level designer tries many seeds).
static func recolor(data: Dictionary, color_seed: int, an := {}) -> void:
	data["jars"] = _assign_colors(data["pieces"], data["colors"], color_seed)
	if data.get("deep_first", false):
		data["jars"] = order_jars(data, an if not an.is_empty() else analyze(data))


## Queue the colours whose screws are buried deepest FIRST. The visible jars then ask for colours the
## player cannot reach yet, so tapping "whatever the jars want" fails and the tray has to be managed.
static func order_jars(data: Dictionary, an: Dictionary) -> Array[String]:
	var colors: Array[String] = []
	for p in data["pieces"]:
		colors.append_array(p["screw_colors"])
	var wait_sum := {}
	var count := {}
	for i in colors.size():
		wait_sum[colors[i]] = wait_sum.get(colors[i], 0) + an["screws"][i]["wait"]
		count[colors[i]] = count.get(colors[i], 0) + 1
	var ranked: Array = wait_sum.keys()
	ranked.sort_custom(func(a: String, b: String) -> bool: return float(wait_sum[a]) / count[a] > float(wait_sum[b]) / count[b])
	var jars: Array[String] = []
	var left := {}
	for c in ranked:
		left[c] = count[c] / 3
	var more := true
	while more:
		more = false
		for c in ranked:
			if left[c] > 0:
				jars.append(c)
				left[c] -= 1
				more = true
	return jars


## Place screws so the puzzle has real dependencies: back pieces first, taking spots hidden under a piece
## in front; pieces in front then fill in around them (their screws are the open entry points). Any two screws stay
## MIN_SCREW_DIST apart, across pieces too.
static func _place_screws(pieces: Array[Dictionary]) -> void:
	var covers: Array = []
	for p in pieces:
		covers.append(_largest(Geometry2D.offset_polygon(p["poly"], 18.0, Geometry2D.JOIN_ROUND)))
	var order: Array = range(pieces.size())
	order.sort_custom(func(x: int, y: int) -> bool: return pieces[x]["plane"] < pieces[y]["plane"])
	var all: Array[Vector2] = []
	var hidden_under := {}   # piece index -> screws already hidden beneath it (capped so it keeps room for its own)
	for pi: int in order:
		var p: Dictionary = pieces[pi]
		var own := PackedVector2Array()
		var min_d := MIN_SCREW_DIST
		while own.size() < p["k"]:
			var best := Vector2.ZERO
			var best_score := -INF
			var best_cover := -1
			for cand: Vector2 in p["spare"]:
				var d := INF
				for q in all:
					d = minf(d, cand.distance_to(q))
				var spread := INF
				for q in own:
					spread = minf(spread, cand.distance_to(q))
				if d < min_d or spread < min_d or not Geometry2D.is_point_in_polygon(cand, p["poly"]):
					continue
				var hidden := 0.0
				var cover_idx := -1
				for qi in pieces.size():
					if pieces[qi]["plane"] > p["plane"] and Geometry2D.is_point_in_polygon(cand, covers[qi]):
						cover_idx = qi
						if hidden_under.get(qi, 0) < 2:
							hidden = 1.0
						break
				var score := hidden * 80.0 + minf(minf(d, spread), 400.0) * 0.1
				if score > best_score:
					best_score = score
					best = cand
					best_cover = cover_idx
			if best_score == -INF:
				if own.size() >= 2 or min_d < MIN_SCREW_DIST * 0.72:
					break
				min_d *= 0.96   # tight piece: relax a little rather than leave it with one screw
				continue
			own.append(best)
			all.append(best)
			if best_cover >= 0:
				hidden_under[best_cover] = hidden_under.get(best_cover, 0) + 1
		p["screws"] = own


## The total number of screws must be a multiple of 3 (jars hold 3).
static func _fix_screw_count(pieces: Array[Dictionary], cell: float) -> void:
	var total := 0
	for p in pieces:
		total += p["screws"].size()
	while total % 3 != 0:
		var worst: Dictionary = {}
		for p in pieces:
			if p["screws"].size() > 2 and (worst.is_empty() or p["screws"].size() > worst["screws"].size()):
				worst = p
		if worst.is_empty():
			break
		var s: PackedVector2Array = worst["screws"]
		s.remove_at(s.size() - 1)
		worst["screws"] = s
		total -= 1
	while total % 3 != 0:  # every piece has exactly two screws: add one where it fits
		var added := false
		for p in pieces:
			var s: PackedVector2Array = p["screws"]
			var cand: Vector2 = (s[0] + s[s.size() - 1]) / 2.0
			var ok := true
			for q in s:
				ok = ok and q.distance_to(cand) >= MIN_SCREW_DIST
			if ok and Geometry2D.is_point_in_polygon(cand, p["poly"]):
				s.append(cand)
				p["screws"] = s
				total += 1
				added = true
				break
		if not added:
			break


static func _assign_colors(pieces: Array[Dictionary], color_count: int, color_seed: int) -> Array[String]:
	var rng := RandomNumberGenerator.new()
	rng.seed = color_seed
	var total := 0
	for p in pieces:
		total += p["screws"].size()
	var names: Array[String] = []
	for k in Levels.COLORS:
		names.append(k)
	var jars: Array[String] = []
	for i in total / 3:
		jars.append(names[i % color_count])
	_shuffle(jars, rng)
	var screw_colors: Array[String] = []
	for j in jars:
		for _i in 3:
			screw_colors.append(j)
	_shuffle(screw_colors, rng)
	var n := 0
	for p in pieces:
		var cols: Array[String] = []
		for _s in p["screws"].size():
			cols.append(screw_colors[n])
			n += 1
		p["screw_colors"] = cols
	return jars


static func _shuffle(a: Array, rng: RandomNumberGenerator) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi() % (i + 1)
		var t = a[i]
		a[i] = a[j]
		a[j] = t


# --- static solvability / difficulty analysis (no physics) ---------------------

## Flat screw list plus, for each screw, the pieces in front of it (higher plane, geometry covers it).
static func analyze(data: Dictionary) -> Dictionary:
	var pieces: Array = data["pieces"]
	var cover_polys: Array = []
	for p in pieces:
		cover_polys.append(_largest(Geometry2D.offset_polygon(p["poly"], 18.0, Geometry2D.JOIN_ROUND)))
	var screws: Array[Dictionary] = []
	for pi in pieces.size():
		for si in pieces[pi]["screws"].size():
			var pos: Vector2 = pieces[pi]["screws"][si]
			var front := PackedInt32Array()
			for qi in pieces.size():
				if pieces[qi]["plane"] > pieces[pi]["plane"] and Geometry2D.is_point_in_polygon(pos, cover_polys[qi]):
					front.append(qi)
			screws.append({"piece": pi, "front": front, "wait": 0})
	# wait = how many "layers" must be cleared before this screw is reachable (front pieces must lose all screws)
	var order: Array = range(pieces.size())
	order.sort_custom(func(x: int, y: int) -> bool: return pieces[x]["plane"] > pieces[y]["plane"])
	var piece_wait := PackedInt32Array()
	piece_wait.resize(pieces.size())
	for pi: int in order:
		var w := 0
		for sh in screws:
			if sh["piece"] != pi:
				continue
			var need := 0
			for q in sh["front"]:
				need = maxi(need, piece_wait[q] + 1)
			sh["wait"] = need
			w = maxi(w, need)
		piece_wait[pi] = w
	return {"screws": screws, "piece_count": pieces.size()}


## One playout under the game's rules. Policies: RANDOM (any legal tap), GREEDY (the human shortcut: tap a
## screw that fits a visible jar, otherwise anything), HEURISTIC (greedy plus releasing pieces and looking ahead).
## Returns {win, max_tray}.
static func simulate(data: Dictionary, an: Dictionary, rng: RandomNumberGenerator, policy: int) -> Dictionary:
	var shapes: Array = an["screws"]
	var pieces: Array = data["pieces"]
	var colors: Array[String] = []
	for p in pieces:
		colors.append_array(p["screw_colors"])
	var n := shapes.size()
	var left := PackedInt32Array()
	left.resize(an["piece_count"])
	for s in shapes:
		left[s["piece"]] += 1
	var alive := PackedByteArray()
	alive.resize(n)
	alive.fill(1)
	var queue: Array = data["jars"].duplicate()
	var jars: Array = []
	for _i in mini(data.get("jars_visible", VISIBLE_JARS), queue.size()):
		jars.append({"color": queue.pop_front(), "n": 0})
	var tray: Array[String] = []
	var tray_cap: int = data.get("tray", TRAY_SIZE)
	var remaining := n
	var max_tray := 0
	while remaining > 0:
		var options: Array[int] = []
		for i in n:
			if alive[i] == 0:
				continue
			var covered := false
			for q in shapes[i]["front"]:
				if left[q] > 0:
					covered = true
					break
			if not covered:
				options.append(i)
		var legal: Array[int] = []
		for i in options:
			if _jar_slot(jars, colors[i]) >= 0 or tray.size() < tray_cap:
				legal.append(i)
		if legal.is_empty():
			return {"win": false, "max_tray": max_tray}
		var pick: int
		if policy == RANDOM:
			pick = legal[rng.randi() % legal.size()]
		elif policy == GREEDY:
			var fitting: Array[int] = []
			for i in legal:
				if _jar_slot(jars, colors[i]) >= 0:
					fitting.append(i)
			var pool := fitting if not fitting.is_empty() else legal
			pick = pool[rng.randi() % pool.size()]
		else:
			pick = legal[0]
			var best := -INF
			for i in legal:
				var score := rng.randf()
				if _jar_slot(jars, colors[i]) >= 0:
					score += 100.0
				else:
					var soon := 9
					for qi in mini(queue.size(), 3):
						if queue[qi] == colors[i]:
							soon = qi
							break
					score += 6.0 - soon * 2.0 - tray.size() * 3.0
				if left[shapes[i]["piece"]] == 1:
					score += 12.0   # releases its piece and may uncover screws
				if score > best:
					best = score
					pick = i
		alive[pick] = 0
		left[shapes[pick]["piece"]] -= 1
		var color := colors[pick]
		var ji := _jar_slot(jars, color)
		if ji >= 0:
			jars[ji]["n"] += 1
		else:
			tray.append(color)
			max_tray = maxi(max_tray, tray.size())
		var changed := true
		while changed:   # complete full jars, open the next one, pull matching screws out of the tray
			changed = false
			for k in jars.size():
				if jars[k]["n"] < 3:
					continue
				remaining -= 3
				if queue.is_empty():
					jars.remove_at(k)
				else:
					jars[k] = {"color": queue.pop_front(), "n": 0}
					var keep: Array[String] = []
					for t in tray:
						if t == jars[k]["color"] and jars[k]["n"] < 3:
							jars[k]["n"] += 1
						else:
							keep.append(t)
					tray = keep
				changed = true
				break
	return {"win": true, "max_tray": max_tray}


static func _jar_slot(jars: Array, color: String) -> int:
	for k in jars.size():
		if jars[k]["color"] == color and jars[k]["n"] < 3:
			return k
	return -1


## Share of screws that can be tapped at the start (low = deep dependency chains).
static func open_share(an: Dictionary) -> float:
	var open := 0
	for s in an["screws"]:
		if s["front"].is_empty():
			open += 1
	return open / float(an["screws"].size())


## Depth-first search for ANY winning order (design-time check that a level is solvable at all).
## Returns {solved, nodes, path} where `path` lists screw indices in a winning order. `node_limit` bounds the search;
## hitting it counts as unsolved. `state` ({alive, left, jars, qi, tray, remaining}) solves from a live position (hints).
static func solve(data: Dictionary, an: Dictionary, node_limit := 400000, state := {}) -> Dictionary:
	var shapes: Array = an["screws"]
	var colors: Array[String] = []
	for p in data["pieces"]:
		colors.append_array(p["screw_colors"])
	var left := PackedInt32Array()
	left.resize(an["piece_count"])
	for sh in shapes:
		left[sh["piece"]] += 1
	var queue: Array = data["jars"]
	var jars: Array = []
	var qi := 0
	for _i in mini(data.get("jars_visible", VISIBLE_JARS), queue.size()):
		jars.append([queue[qi], 0])
		qi += 1
	var ctx := {"nodes": 0, "seen": {}, "limit": node_limit, "shapes": shapes, "colors": colors, "queue": queue,
		"tray_cap": data.get("tray", TRAY_SIZE), "path": []}
	var ok := false
	if state.is_empty():
		ok = _dfs(ctx, (1 << shapes.size()) - 1, left, jars, qi, {}, shapes.size())
	else:
		ok = _dfs(ctx, state["alive"], state["left"], state["jars"], state["qi"], state["tray"], state["remaining"])
	return {"solved": ok, "nodes": ctx["nodes"], "path": ctx["path"]}


static func _dfs(ctx: Dictionary, alive: int, left: PackedInt32Array, jars: Array, qi: int, tray: Dictionary, remaining: int) -> bool:
	if remaining <= 0:
		return true
	ctx["nodes"] += 1
	if ctx["nodes"] > ctx["limit"]:
		return false
	var jar_key := ""
	for j in jars:
		jar_key += "%s%d," % [j[0], j[1]]
	var tray_keys: Array = tray.keys()
	tray_keys.sort()
	var tray_key := ""
	for k in tray_keys:
		tray_key += "%s%d," % [k, tray[k]]
	var key := "%d|%s|%d|%s" % [alive, jar_key, qi, tray_key]
	if ctx["seen"].has(key):
		return false
	ctx["seen"][key] = true
	var shapes: Array = ctx["shapes"]
	var colors: Array = ctx["colors"]
	var tray_size := 0
	for k in tray:
		tray_size += tray[k]
	var moves: Array = []   # [score, index]
	for i in shapes.size():
		if (alive >> i) & 1 == 0:
			continue
		var covered := false
		for q in shapes[i]["front"]:
			if left[q] > 0:
				covered = true
				break
		if covered:
			continue
		var fits := false
		for j in jars:
			if j[0] == colors[i] and j[1] < 3:
				fits = true
		if not fits and tray_size >= ctx["tray_cap"]:
			continue
		var score := (100 if fits else 0) + (20 if left[shapes[i]["piece"]] == 1 else 0)
		moves.append([score, i])
	moves.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	for m in moves:
		var i: int = m[1]
		var nleft := left.duplicate()
		nleft[shapes[i]["piece"]] -= 1
		var njars: Array = []
		for j in jars:
			njars.append(j.duplicate())
		var ntray := tray.duplicate()
		var nq := qi
		var nrem := remaining
		var placed := false
		for j in njars:
			if j[0] == colors[i] and j[1] < 3:
				j[1] += 1
				placed = true
				break
		if not placed:
			ntray[colors[i]] = ntray.get(colors[i], 0) + 1
		var changed := true
		while changed:
			changed = false
			for k in njars.size():
				if njars[k][1] < 3:
					continue
				nrem -= 3
				if nq >= ctx["queue"].size():
					njars.remove_at(k)
				else:
					njars[k] = [ctx["queue"][nq], 0]
					nq += 1
					var c: String = njars[k][0]
					var take: int = mini(ntray.get(c, 0), 3)
					if take > 0:
						njars[k][1] = take
						ntray[c] -= take
						if ntray[c] == 0:
							ntray.erase(c)
				changed = true
				break
		if _dfs(ctx, alive & ~(1 << i), nleft, njars, nq, ntray, nrem):
			ctx["path"].push_front(i)
			return true
	return false
