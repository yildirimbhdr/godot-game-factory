class_name Board
extends Control
## Draws the level and handles taps on mirrors. Beams live in a child layer with additive blending.

signal flipped(index: int)
signal undone(index: int)
signal crystal_lit(open_count: int, index: int)
signal solved

const COLORS := {1: Color("FF4D6D"), 2: Color("3DDC97"), 4: Color("4D9BFF"), 3: Color("FFD166"), 5: Color("D65DB1"), 6: Color("5DE0E6"), 7: Color("FFFFFF")}
const GLASS := Color("B8C4FF")
const CELL_COLOR := Color("232B52")
const PANEL_COLOR := Color("1A2040")
const MARGIN := 20.0

var level: Dictionary = {}
var kinds: Array = []
var result: Dictionary = {}
var cell := 100.0
var origin := Vector2.ZERO
## Animation scale; 0 makes everything instant (playtests, lesson 0027).
var fx := 1.0:
	set(v):
		fx = v
		set_process(v > 0.0)
var reveal := 0.0:
	set(v):
		reveal = v
		_beams.queue_redraw()

var _angles: Array[float] = []
var _open_t: Array[float] = []
var _ring_t: Array[float] = []
var _was_open: Array[bool] = []
var _beams: Control
var _cell_style := StyleBoxFlat.new()
var _sheen_style := StyleBoxFlat.new()
var _panel_style := StyleBoxFlat.new()
var _done := false
var _time := 0.0
var _occupied := {}
## Per beam segment: distance from the flipped mirror (or from the lamp at level start) while it re-forms, -1 when it is static.
var _seg_d: Array[float] = []
var _beam_tween: Tween
## Accent colour of the current world (board border, corner brackets).
var accent := Color("B8C4FF")
var _history: Array[int] = []
var _hint_index := -1
var _hint_t := 0.0
var _hint_tween: Tween


func _ready() -> void:
	_beams = Control.new()
	_beams.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_beams.set_anchors_preset(Control.PRESET_FULL_RECT)
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_beams.material = add
	_beams.draw.connect(_draw_beams)
	add_child(_beams)
	_cell_style.bg_color = CELL_COLOR
	_sheen_style.bg_color = Color(1, 1, 1, 0.045)
	_panel_style.bg_color = PANEL_COLOR
	_panel_style.shadow_color = Color(0, 0, 0, 0.35)
	_panel_style.shadow_size = 24
	resized.connect(_layout)


func _process(delta: float) -> void:
	_time += delta   # ambient life: lamps breathe, open crystals twinkle, beams shimmer
	queue_redraw()
	_beams.queue_redraw()


func mirror_point(index: int) -> Vector2:
	return global_position + cell_center(Vector2(level.mirrors[index].x, level.mirrors[index].y))


func crystal_point(index: int) -> Vector2:
	return global_position + cell_center(Vector2(level.crystals[index].x, level.crystals[index].y))


func board_center() -> Vector2:
	return global_position + origin + Vector2(level.w, level.h) * cell / 2.0


func setup(new_level: Dictionary) -> void:
	level = new_level
	kinds = (level.get("mirrors", []) as Array).map(func(m: Dictionary) -> int: return int(m.kind))
	_angles.clear()
	for k: int in kinds:
		_angles.append(_angle_for(k))
	_open_t.clear()
	_ring_t.clear()
	_was_open.clear()
	for _c in (level.get("crystals", []) as Array).size():
		_open_t.append(0.0)
		_ring_t.append(1.0)
		_was_open.append(false)
	_done = false
	_history.clear()
	_hint_index = -1
	_layout()
	_occupied.clear()
	for key in ["mirrors", "crystals", "lamps", "splitters", "filters", "mixers"]:
		for e: Dictionary in level.get(key, []):
			_occupied[Vector2i(e.x, e.y)] = true
	for w: Array in level.get("walls", []):
		_occupied[Vector2i(w[0], w[1])] = true
	_retrace(false)
	if fx > 0.0:   # one draw-in from the lamps when the level starts
		_seg_d.clear()
		for seg: Dictionary in result.segments:
			_seg_d.append(float(seg.off))
		_start_reform(float(result.total), 0.12)


func flip(index: int) -> void:
	if _done or index < 0 or index >= kinds.size() or level.mirrors[index].get("fixed", false):
		return
	_history.append(index)
	_apply(index)
	flipped.emit(index)


## Takes back the last flip. Returns false when there is nothing to undo.
func undo() -> bool:
	if _done or _history.is_empty():
		return false
	var index: int = _history.pop_back()
	_apply(index)
	undone.emit(index)
	return true


func can_undo() -> bool:
	return not _done and not _history.is_empty()


func show_hint(index: int) -> void:
	_hint_index = index
	if _hint_tween:
		_hint_tween.kill()
	if fx > 0.0:
		_hint_tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_hint_tween.tween_method(_set_hint, 0.0, 1.0, 0.5)
		_hint_tween.tween_method(_set_hint, 1.0, 0.0, 0.5)
	else:
		_hint_t = 1.0
	queue_redraw()


func _set_hint(v: float) -> void:
	_hint_t = v
	queue_redraw()


func _apply(index: int) -> void:
	kinds[index] = 1 - int(kinds[index])
	_hint_index = -1
	if _hint_tween:
		_hint_tween.kill()
	var target := _angle_for(int(kinds[index]))
	if fx > 0.0:
		create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT) \
			.tween_method(_set_angle.bind(index), _angles[index], target, 0.22 * fx)
	else:
		_set_angle(target, index)
	_retrace(true, index)


func mirror_at(c: Vector2i) -> int:
	var mirrors: Array = level.get("mirrors", [])
	for i in mirrors.size():
		if mirrors[i].x == c.x and mirrors[i].y == c.y:
			return i
	return -1


func cell_center(c: Vector2) -> Vector2:
	return origin + (c + Vector2(0.5, 0.5)) * cell


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var c := Vector2i(((event.position - origin) / cell).floor())
		var i := mirror_at(c)
		if i >= 0:
			flip(i)
			accept_event()


func _layout() -> void:
	if level.is_empty():
		return
	var avail := size - Vector2.ONE * MARGIN * 2.0
	cell = floorf(minf(avail.x / float(level.w), avail.y / float(level.h)))
	cell = minf(cell, 170.0)
	origin = ((size - Vector2(level.w, level.h) * cell) / 2.0).floor()
	queue_redraw()
	_beams.queue_redraw()


func _retrace(animate: bool, from_mirror := -1) -> void:
	result = Optics.trace(level, kinds)
	_seg_d.clear()
	if _beam_tween:
		_beam_tween.kill()
	var open: Array = result.open
	for i in open.size():
		if open[i] and not _was_open[i]:
			_was_open[i] = true
			_pop_crystal(i, animate)
			if animate:
				crystal_lit.emit(_was_open.count(true), i)
		elif not open[i]:
			_was_open[i] = false
			_open_t[i] = 0.0
	reveal = float(result.total) + 0.5
	if animate and fx > 0.0 and from_mirror >= 0:
		_reform_from(from_mirror)
	queue_redraw()
	if Optics.is_solved(open) and not _done:
		_done = true
		solved.emit()


## Only the light that leaves the flipped mirror re-forms, quickly, travelling along its new path; everything upstream stays lit.
func _reform_from(index: int) -> void:
	var center := Vector2(level.mirrors[index].x + 0.5, level.mirrors[index].y + 0.5)
	var segs: Array = result.segments
	var depth: Array[float] = []
	depth.resize(segs.size())
	depth.fill(-1.0)
	var queue: Array[int] = []
	for i in segs.size():
		if (segs[i].a as Vector2).distance_to(center) < 0.01:
			depth[i] = 0.0
			queue.append(i)
	var longest := 0.0
	while not queue.is_empty():
		var i: int = queue.pop_front()
		var end: Vector2 = segs[i].b
		var span: float = (segs[i].a as Vector2).distance_to(end)
		longest = maxf(longest, depth[i] + span)
		for j in segs.size():
			if depth[j] < 0.0 and (segs[j].a as Vector2).distance_to(end) < 0.01:
				depth[j] = depth[i] + span
				queue.append(j)
	if longest <= 0.0:
		return   # no beam touches this mirror: nothing to re-form
	_seg_d.assign(depth)
	_start_reform(longest, 0.04)


func _start_reform(distance: float, base_time: float) -> void:
	reveal = 0.0
	_beam_tween = create_tween()
	_beam_tween.tween_property(self, "reveal", distance + 0.5, base_time + distance / 24.0 * fx)


func _pop_crystal(i: int, animate: bool) -> void:
	if not animate or fx <= 0.0:
		_open_t[i] = 1.0
		_ring_t[i] = 1.0
		return
	var t := create_tween().set_parallel(true)
	t.tween_method(_set_open.bind(i), 0.0, 1.0, 0.3 * fx).set_delay(0.04 * fx)
	t.tween_method(_set_ring.bind(i), 0.0, 1.0, 0.6 * fx).set_delay(0.04 * fx)


func _set_angle(v: float, i: int) -> void:
	_angles[i] = v
	queue_redraw()


func _set_open(v: float, i: int) -> void:
	_open_t[i] = v
	queue_redraw()


func _set_ring(v: float, i: int) -> void:
	_ring_t[i] = v
	queue_redraw()


func _angle_for(kind: int) -> float:
	return -PI / 4.0 if kind == 0 else PI / 4.0


func _draw() -> void:
	if level.is_empty():
		return
	var board := Rect2(origin, Vector2(level.w, level.h) * cell).grow(cell * 0.12)
	_panel_style.set_corner_radius_all(int(cell * 0.28))
	_panel_style.border_color = Color(accent, 0.6)
	_panel_style.set_border_width_all(3)
	_panel_style.shadow_color = Color(accent, 0.22)
	_panel_style.shadow_size = 34
	_panel_style.draw(get_canvas_item(), board)
	_draw_brackets(board)
	_cell_style.set_corner_radius_all(int(cell * 0.14))
	for y in int(level.h):
		for x in int(level.w):
			var cell_rect := Rect2(origin + Vector2(x, y) * cell, Vector2.ONE * cell).grow(-cell * 0.04)
			_cell_style.draw(get_canvas_item(), cell_rect)
			_sheen_style.set_corner_radius_all(int(cell * 0.1))
			_sheen_style.draw(get_canvas_item(), Rect2(cell_rect.position + Vector2(cell * 0.05, cell * 0.04), Vector2(cell_rect.size.x - cell * 0.1, cell_rect.size.y * 0.38)))
	for y in int(level.h):
		for x in int(level.w):
			if not _occupied.has(Vector2i(x, y)):
				draw_circle(cell_center(Vector2(x, y)), cell * 0.035, Color(accent, 0.16))
	for w: Array in level.get("walls", []):
		_draw_wall(Vector2i(w[0], w[1]))
	for lamp: Dictionary in level.get("lamps", []):
		_draw_lamp(lamp)
	for f: Dictionary in level.get("filters", []):
		_draw_filter(f)
	for m: Dictionary in level.get("mixers", []):
		_draw_mixer(m)
	for s: Dictionary in level.get("splitters", []):
		_draw_splitter(s)
	var mirrors: Array = level.get("mirrors", [])
	for i in mirrors.size():
		_draw_mirror(i, mirrors[i])
	var crystals: Array = level.get("crystals", [])
	for i in crystals.size():
		_draw_crystal(i, crystals[i])


func _draw_brackets(board: Rect2) -> void:
	var l := cell * 0.34
	var col := Color(accent, 0.85)
	var w := 5.0
	var r := board.grow(-2.0)
	for corner in 4:
		var p := r.position + Vector2(r.size.x if corner % 2 == 1 else 0.0, r.size.y if corner >= 2 else 0.0)
		var sx := -1.0 if corner % 2 == 1 else 1.0
		var sy := -1.0 if corner >= 2 else 1.0
		draw_polyline(PackedVector2Array([p + Vector2(0, sy * l), p, p + Vector2(sx * l, 0)]), col, w, true)


func _draw_wall(c: Vector2i) -> void:
	var r := Rect2(origin + Vector2(c) * cell, Vector2.ONE * cell).grow(-cell * 0.1)
	var s := StyleBoxFlat.new()
	s.bg_color = Color("12172F")
	s.border_color = Color("333D75")
	s.set_border_width_all(3)
	s.set_corner_radius_all(int(cell * 0.12))
	s.draw(get_canvas_item(), r)


func _draw_lamp(lamp: Dictionary) -> void:
	var c := cell_center(Vector2(lamp.x, lamp.y))
	var col: Color = COLORS[lamp.color]
	draw_circle(c, cell * 0.34, Color("11162E"))
	draw_arc(c, cell * 0.34, 0, TAU, 40, col.darkened(0.2), 5.0, true)
	draw_circle(c, cell * 0.27, Color(col, 0.16))
	draw_circle(c, cell * 0.16 * (1.0 + 0.14 * sin(_time * 3.0 + c.x)), col)
	draw_circle(c + Vector2(-cell * 0.07, -cell * 0.09), cell * 0.05, Color(1, 1, 1, 0.85))
	var d := Vector2(Optics.DIRS[lamp.dir])
	var n := d.orthogonal()
	var tip := c + d * cell * 0.46
	draw_colored_polygon(PackedVector2Array([c + d * cell * 0.28 + n * cell * 0.13, tip, c + d * cell * 0.28 - n * cell * 0.13]), col)


func _draw_mirror(i: int, m: Dictionary) -> void:
	var c := cell_center(Vector2(m.x, m.y))
	var a := _angles[i]
	var half := Vector2.RIGHT.rotated(a) * cell * 0.4
	var fixed: bool = m.get("fixed", false)
	draw_circle(c, cell * 0.43, Color(1, 1, 1, 0.04 if not fixed else 0.0))
	draw_line(c - half, c + half, Color(GLASS, 0.14), cell * 0.3, true)
	draw_line(c - half, c + half, Color("2E376B"), cell * 0.17, true)
	draw_line(c - half, c + half, GLASS if not fixed else GLASS.darkened(0.45), cell * 0.1, true)
	var shine := half.orthogonal().normalized() * cell * 0.025
	draw_line(c - half * 0.8 + shine, c + half * 0.8 + shine, Color(1, 1, 1, 0.85), cell * 0.025, true)
	draw_circle(c, cell * 0.075, Color("2E376B"))
	draw_circle(c, cell * 0.045, Color(GLASS, 0.9))
	if i == _hint_index:
		draw_arc(c, cell * (0.42 + 0.06 * _hint_t), 0, TAU, 40, Color("FFD166", 0.55 + 0.45 * _hint_t), 6.0, true)


func _draw_splitter(s: Dictionary) -> void:
	var c := cell_center(Vector2(s.x, s.y))
	var half := Vector2.RIGHT.rotated(_angle_for(s.kind)) * cell * 0.4
	draw_circle(c, cell * 0.3, Color("11162E"))
	draw_arc(c, cell * 0.3, 0, TAU, 40, Color("5DE0E6"), 4.0, true)
	draw_line(c - half * 0.75, c + half * 0.75, GLASS, cell * 0.07, true)
	draw_circle(c, cell * 0.09, Color("5DE0E6"))


func _draw_filter(f: Dictionary) -> void:
	var c := cell_center(Vector2(f.x, f.y))
	var col: Color = COLORS[f.color]
	draw_circle(c, cell * 0.3, Color(col, 0.18))
	draw_arc(c, cell * 0.3, 0, TAU, 40, col, 6.0, true)


func _draw_mixer(m: Dictionary) -> void:
	var c := cell_center(Vector2(m.x, m.y))
	draw_circle(c, cell * 0.34, Color("11162E"))
	for k in 3:
		var p := c + Vector2.from_angle(-PI / 2.0 + k * TAU / 3.0) * cell * 0.15
		draw_circle(p, cell * 0.1, COLORS[1 << k])
	var d := Vector2(Optics.DIRS[m.out])
	draw_colored_polygon(PackedVector2Array([c + d * cell * 0.46, c + d * cell * 0.3 + d.orthogonal() * cell * 0.1, c + d * cell * 0.3 - d.orthogonal() * cell * 0.1]), GLASS)


func _draw_crystal(i: int, cr: Dictionary) -> void:
	var c := cell_center(Vector2(cr.x, cr.y))
	var col: Color = COLORS[cr.color]
	var t := _open_t[i]
	var r := cell * 0.3
	var pts := PackedVector2Array()
	for k in 6:
		pts.append(c + Vector2.from_angle(-PI / 2.0 + k * TAU / 6.0) * r)
	if t > 0.0:
		var twinkle := 0.5 + 0.5 * sin(_time * 2.4 + float(i) * 1.7)
		draw_circle(c, r * (1.5 + 0.25 * t + 0.12 * twinkle), Color(col, (0.14 + 0.1 * twinkle) * t))
	var shades := [0.5, 0.28, 0.02, -0.3, -0.12, 0.22]   # light from the upper left: each facet gets its own brightness
	for k in 6:
		var shade: float = shades[k]
		var lit := col.lightened(shade) if shade > 0.0 else col.darkened(-shade)
		var dark := Color("11162E").lightened(0.05 + 0.03 * k)
		draw_colored_polygon(PackedVector2Array([c, pts[k], pts[(k + 1) % 6]]), dark.lerp(lit, t))
	draw_circle(c + Vector2(-r * 0.3, -r * 0.4), r * 0.1, Color(1, 1, 1, 0.35 + 0.5 * t))
	pts.append(pts[0])
	draw_polyline(pts, col if t > 0.0 else col.darkened(0.15), 5.0, true)
	var ring := _ring_t[i]
	if ring < 1.0:
		draw_arc(c, r * (1.0 + 1.1 * ring), 0, TAU, 48, Color(col, 1.0 - ring), 5.0, true)


func _draw_beams() -> void:
	var segs: Array = result.get("segments", [])
	for i in segs.size():
		var s: Dictionary = segs[i]
		var a: Vector2 = s.a
		var b: Vector2 = s.b
		var length := a.distance_to(b)
		var d: float = _seg_d[i] if i < _seg_d.size() else -1.0
		var vis := length if d < 0.0 else clampf(reveal - d, 0.0, length)
		if vis <= 0.0:
			continue
		var pa := origin + a * cell
		var pb := origin + (a + (b - a) / length * vis) * cell
		var col: Color = COLORS[s.color]
		var shimmer := 0.03 * sin(_time * 6.0)
		_beams.draw_line(pa, pb, Color(col, 0.16 + shimmer), cell * 0.34, true)
		_beams.draw_line(pa, pb, Color(col, 0.38), cell * 0.17, true)
		_beams.draw_line(pa, pb, col.lerp(Color.WHITE, 0.65), cell * 0.06, true)
		if d >= 0.0 and vis < length:   # bright head while the beam is travelling
			_beams.draw_circle(pb, cell * 0.2, Color(col, 0.55))
			_beams.draw_circle(pb, cell * 0.09, Color.WHITE)
