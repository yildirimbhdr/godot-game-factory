class_name Optics
extends RefCounted
## Pure beam logic, no drawing: trace a level for given mirror states, and solve it by search.
## Directions 0=up 1=right 2=down 3=left. Colours are bit masks R=1 G=2 B=4 (white = 7).
## A level is a Dictionary: w, h, lamps, mirrors, crystals, walls, mixers, splitters, filters, par (see levels.gd).

const UP := 0
const RIGHT := 1
const DOWN := 2
const LEFT := 3
const DIRS: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
const REFLECT_SLASH: Array[int] = [1, 0, 3, 2]       # '/'  : up->right, right->up, down->left, left->down
const REFLECT_BACKSLASH: Array[int] = [3, 2, 1, 0]   # '\'  : up->left, right->down, down->right, left->up
const MAX_STEPS := 400


static func reflect(kind: int, dir: int) -> int:
	return REFLECT_SLASH[dir] if kind == 0 else REFLECT_BACKSLASH[dir]


## Result: {segments: [{a: Vector2, b: Vector2, color: int, off: float}], open: Array[bool], total: float}
## `kinds` holds the current kind (0 '/', 1 '\') of every entry of level.mirrors.
static func trace(level: Dictionary, kinds: Array) -> Dictionary:
	var grid := _build_grid(level, kinds)
	var crystals: Array = level.get("crystals", [])
	var mixer_in := {}
	var result := {}
	for _pass in 8:
		var hits: Array = []
		for _i in crystals.size():
			hits.append([])
		var new_mixer_in := {}
		var segments: Array = []
		var seen := {}   # shared by every beam of the pass: a splitter loop must not spawn beams forever
		var queue: Array = []
		for lamp: Dictionary in level.get("lamps", []):
			queue.append({"cell": Vector2i(lamp.x, lamp.y), "dir": lamp.dir, "mask": lamp.color, "dist": 0.0})
		for key: Vector2i in mixer_in:
			var mixer: Dictionary = grid[key].data
			queue.append({"cell": key, "dir": mixer.out, "mask": mixer_in[key], "dist": 0.0})
		while not queue.is_empty():
			_run_beam(level, grid, queue.pop_back(), queue, segments, hits, new_mixer_in, seen)
		var open: Array[bool] = []
		for i in crystals.size():
			open.append((hits[i] as Array).has(int(crystals[i].color)))
		var total := 0.0
		for s: Dictionary in segments:
			total = maxf(total, s.off + (s.a as Vector2).distance_to(s.b))
		result = {"segments": segments, "open": open, "total": total}
		if new_mixer_in == mixer_in:
			break
		mixer_in = new_mixer_in
	return result


static func is_solved(open: Array) -> bool:
	return not open.is_empty() and not open.has(false)


## Fewest taps to clear the level from its starting mirror states, or -1 when impossible.
## Also returns the winning kinds so a hint can point at the first mirror to flip.
static func solve(level: Dictionary, start_kinds: Array = []) -> Dictionary:
	var mirrors: Array = level.get("mirrors", [])
	var start: Array = start_kinds if not start_kinds.is_empty() else mirrors.map(func(m: Dictionary) -> int: return int(m.kind))
	var free: Array[int] = []
	for i in mirrors.size():
		if not mirrors[i].get("fixed", false):
			free.append(i)
	var best := -1
	var best_kinds: Array = []
	for bits in 1 << free.size():
		var kinds := start.duplicate()
		var flips := 0
		for j in free.size():
			if (bits >> j) & 1:
				kinds[free[j]] = 1 - int(kinds[free[j]])
				flips += 1
		if best != -1 and flips >= best:
			continue
		if is_solved(trace(level, kinds).open):
			best = flips
			best_kinds = kinds
	return {"par": best, "kinds": best_kinds}


static func _build_grid(level: Dictionary, kinds: Array) -> Dictionary:
	var grid := {}
	for w: Array in level.get("walls", []):
		grid[Vector2i(w[0], w[1])] = {"type": "wall"}
	for lamp: Dictionary in level.get("lamps", []):
		grid[Vector2i(lamp.x, lamp.y)] = {"type": "wall"}
	var mirrors: Array = level.get("mirrors", [])
	for i in mirrors.size():
		grid[Vector2i(mirrors[i].x, mirrors[i].y)] = {"type": "mirror", "kind": int(kinds[i])}
	var crystals: Array = level.get("crystals", [])
	for i in crystals.size():
		grid[Vector2i(crystals[i].x, crystals[i].y)] = {"type": "crystal", "index": i}
	for m: Dictionary in level.get("mixers", []):
		grid[Vector2i(m.x, m.y)] = {"type": "mixer", "data": m}
	for s: Dictionary in level.get("splitters", []):
		grid[Vector2i(s.x, s.y)] = {"type": "splitter", "kind": int(s.kind)}
	for f: Dictionary in level.get("filters", []):
		grid[Vector2i(f.x, f.y)] = {"type": "filter", "color": int(f.color)}
	return grid


static func _center(cell: Vector2i) -> Vector2:
	return Vector2(cell) + Vector2(0.5, 0.5)


static func _run_beam(level: Dictionary, grid: Dictionary, beam: Dictionary, queue: Array, segments: Array, hits: Array, mixer_in: Dictionary, seen: Dictionary) -> void:
	var cell: Vector2i = beam.cell
	var dir: int = beam.dir
	var mask: int = beam.mask
	var dist: float = beam.dist
	var start := _center(cell)
	for _step in MAX_STEPS:
		var key := Vector3i(cell.x * 8 + dir, cell.y, mask)
		if seen.has(key):
			return
		seen[key] = true
		var next := cell + DIRS[dir]
		if next.x < 0 or next.y < 0 or next.x >= level.w or next.y >= level.h:
			_add(segments, start, _center(cell) + Vector2(DIRS[dir]) * 0.5, mask, dist)
			return
		var obj: Variant = grid.get(next)
		if obj == null:
			cell = next
			continue
		var c := _center(next)
		match obj.type:
			"wall":
				_add(segments, start, c - Vector2(DIRS[dir]) * 0.5, mask, dist)
				return
			"crystal":
				_add(segments, start, c, mask, dist)
				(hits[obj.index] as Array).append(mask)
				return
			"mixer":
				_add(segments, start, c, mask, dist)
				mixer_in[next] = int(mixer_in.get(next, 0)) | mask
				return
			"mirror":
				dist += _add(segments, start, c, mask, dist)
				dir = reflect(obj.kind, dir)
				start = c
				cell = next
			"splitter":
				dist += _add(segments, start, c, mask, dist)
				queue.append({"cell": next, "dir": reflect(obj.kind, dir), "mask": mask, "dist": dist})
				start = c
				cell = next
			"filter":
				dist += _add(segments, start, c, mask, dist)
				mask &= int(obj.color)
				if mask == 0:
					return
				start = c
				cell = next


static func _add(segments: Array, a: Vector2, b: Vector2, mask: int, dist: float) -> float:
	segments.append({"a": a, "b": b, "color": mask, "off": dist})
	return a.distance_to(b)
