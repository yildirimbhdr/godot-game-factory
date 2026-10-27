class_name Game
extends Control
## Unwind: unscrew plates held by coloured screws. A screw flies to the jar of its colour (3 fill a jar)
## or waits in the 5-slot tray; a full tray with no possible move ends the run. Plates are rigid bodies
## pinned by their screws, so they swing and fall when screws are removed.

const GAME_OVER := preload("res://ui/game_over.tscn")
const JAR_X_BY_COUNT := {1: [540.0], 2: [375.0, 705.0], 3: [210.0, 540.0, 870.0]}
const JAR_Y := 330.0
const TRAY_SPACING := 200.0
const HINTS_PER_LEVEL := 3
const HINT_NODE_LIMIT := 60000
const TRAY_Y := 1765.0
const TAP_RADIUS := Screw.R + 18.0
const LEVEL_MAP := "res://ui/level_map.tscn"
const OUTLINE := Color("5B4B8A")
const MAX_LIVES := 3
const COMBO_WORDS := {3: "Nice!", 5: "Great!", 8: "Awesome!", 12: "Perfect!"}

static var level_index := 0

var _plates: Array[Piece] = []
var _jars: Array[Jar] = []
var _tray: Array[Screw] = []
var _queue: Array[String] = []
var _remaining := 0
var _busy := 0
var _over := false
var _moves := 0
var _combo := 0
var _tray_peak := 0
var _total := 0
var _filled := 0
var _shown := 0.0
var _bar: Node2D
var _camera: Camera2D
var _gfx: GameFx
var _lives_view: LivesView
var _last_mistake := -10.0
var _cover_dirty := true
var _base_pos := Vector2.ZERO
var _anchor := StaticBody2D.new()
var _jar_x: Array = []
var _tray_xs: Array[float] = []
var _world_theme: Dictionary = {}
var _data: Dictionary = {}
var _analysis: Dictionary = {}
var _all_screws: Array[Screw] = []
var _pieces_all: Array[Piece] = []
var _total_jars := 0
var _hints_left := HINTS_PER_LEVEL
var _hint_badge: Label
var _hint_ring: Node2D
var _hint_pending := false
var _hint_earning := false
var _hint_button: Button

@onready var _hud: Control = %Hud
@onready var _world: Node2D = %World
@onready var _fx: Node2D = %Fx


func _ready() -> void:
	if OS.has_environment("UNWIND_LEVEL"):  # playtests start at any level
		level_index = int(OS.get_environment("UNWIND_LEVEL")) - 1
	level_index = clampi(level_index, 0, Levels.DATA.size() - 1)
	PauseManager.set_gameplay_active(true)
	AudioManager.play_music("gameplay")
	add_to_group("game")
	Analytics.log_event("level_start", {"level_name": str(level_index + 1)})
	# Design space is 1080x1920; wider or taller screens expand the viewport, so centre the board in it.
	var view := get_viewport_rect().size
	_world.position = Vector2(maxf(view.x - 1080.0, 0.0), maxf(view.y - 1920.0, 0.0)) / 2.0
	_world.add_child(_anchor)
	_base_pos = _world.position
	_camera = Camera2D.new()   # shakes the view; moving the physics parent instead teleports bodies every frame
	_camera.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	add_child(_camera)
	_gfx = GameFx.new()
	add_child(_gfx)
	_gfx.setup(_fx, _camera, Levels.COLORS, OUTLINE)
	_lives_view = LivesView.new().setup(MAX_LIVES, Vector2(get_viewport_rect().size.x / 2.0, 178.0))
	add_child(_lives_view)
	var data := Figure.build(Levels.DATA[level_index])
	_data = data
	_analysis = Figure.analyze(data)
	_world_theme = Levels.world_of(level_index)
	$Backdrop.set_palette(_world_theme["top"], _world_theme["bottom"], _world_theme["blobs"])
	for k in int(data["tray"]):
		_tray_xs.append(540.0 + (k - (int(data["tray"]) - 1) / 2.0) * (TRAY_SPACING if int(data["tray"]) <= 3 else 140.0))
	_hud.set_title("Level %d" % (level_index + 1))
	_build_board(data)
	_build_tray()
	_build_pieces(data)
	_total = _remaining
	_build_progress_bar()
	_queue.assign(data["jars"])
	_total_jars = _queue.size()
	_build_hint_button()
	_jar_x = JAR_X_BY_COUNT[clampi(mini(_queue.size(), data["jars_visible"]), 1, 3)]
	for i in _jar_x.size():
		_open_jar(i, false)


func _build_progress_bar() -> void:
	_bar = Node2D.new()
	_bar.z_index = 150
	add_child(_bar)
	_bar.draw.connect(func() -> void:
		var w := get_viewport_rect().size.x
		var rect := Rect2(w / 2.0 - 230.0, 96.0, 460.0, 38.0)
		var track := StyleBoxFlat.new()
		track.bg_color = Color("D9CCF2")
		track.border_color = OUTLINE
		track.set_border_width_all(6)
		track.set_corner_radius_all(19)
		_bar.draw_style_box(track, rect)
		if _shown > 0.01:
			var fill := StyleBoxFlat.new()
			fill.bg_color = Color("FFC93C").lerp(Color("3FC79A"), _shown)
			fill.set_corner_radius_all(14)
			_bar.draw_style_box(fill, Rect2(rect.position + Vector2(6, 6), Vector2((rect.size.x - 12.0) * _shown, rect.size.y - 12.0)))
		var star: Texture2D = load("res://assets/art/icons/star.png")
		_bar.draw_texture_rect(star, Rect2(rect.end.x - 40.0, rect.position.y - 26.0, 84.0, 84.0), false))


func _set_progress(value: float) -> void:
	create_tween().tween_method(func(v: float) -> void:
		_shown = v
		_bar.queue_redraw(), _shown, value, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## Rounded board behind the figure, with a ghost hole for every screw so fallen pieces reveal it.
func _build_board(data: Dictionary) -> void:
	var board := Node2D.new()
	var rect: Rect2 = (data["bounds"] as Rect2).grow(64.0)
	var holes := PackedVector2Array()
	for p in data["pieces"]:
		holes.append_array(p["screws"])
	board.draw.connect(func() -> void:
		var shadow := StyleBoxFlat.new()
		shadow.bg_color = Color(_world_theme["border"], 0.25)
		shadow.set_corner_radius_all(64)
		board.draw_style_box(shadow, Rect2(rect.position + Vector2(0, 14), rect.size))
		var box := StyleBoxFlat.new()
		box.bg_color = _world_theme["board"]
		box.border_color = _world_theme["border"]
		box.set_border_width_all(8)
		box.set_corner_radius_all(64)
		board.draw_style_box(box, rect)
		for h in holes:
			board.draw_circle(h, Screw.R * 0.9, Color(OUTLINE, 0.16))
			board.draw_arc(h, Screw.R * 0.9, 0.0, TAU, 32, Color(OUTLINE, 0.35), 4.0, true))
	_world.add_child(board)
	board.queue_redraw()


func _build_tray() -> void:
	var tray := Node2D.new()
	tray.draw.connect(func() -> void:
		var box := StyleBoxFlat.new()
		box.bg_color = Color("E9DDFB")
		box.border_color = OUTLINE
		box.set_border_width_all(6)
		box.set_corner_radius_all(48)
		tray.draw_style_box(box, Rect2(_tray_xs[0] - 96, TRAY_Y - 80, _tray_xs[_tray_xs.size() - 1] - _tray_xs[0] + 192, 160))
		for x in _tray_xs:
			tray.draw_circle(Vector2(x, TRAY_Y + 4), 56, Color(OUTLINE, 0.18))
			tray.draw_arc(Vector2(x, TRAY_Y + 4), 56, 0.0, TAU, 40, Color(OUTLINE, 0.55), 5.0, true))
	_world.add_child(tray)
	tray.queue_redraw()
	_tray.resize(_tray_xs.size())


func _build_pieces(data: Dictionary) -> void:
	var screws: Array[Screw] = []
	for d in data["pieces"]:
		var piece := Piece.new()
		_world.add_child(piece)
		piece.setup(d["poly"], d["screws"], d["plane"], d["fill"])
		_plates.append(piece)
		_pieces_all.append(piece)
		for i in d["screws"].size():
			var screw := Screw.new().setup(d["screw_colors"][i])
			screw.plate = piece
			screw.z_index = 1
			piece.add_child(screw)
			screw.global_position = _world.to_global(d["screws"][i])
			piece.screws.append(screw)
			_remaining += 1
			screws.append(screw)
			_all_screws.append(screw)
	for screw in screws:
		var j := PinJoint2D.new()
		j.position = screw.global_position - _world.global_position
		_world.add_child(j)
		j.node_a = j.get_path_to(screw.plate)
		j.node_b = j.get_path_to(_anchor)
		screw.joint = j


func _open_jar(slot: int, animate := true) -> void:
	if _queue.is_empty():
		return
	var jar := Jar.new().setup(_queue.pop_front())
	jar.position = Vector2(_jar_x[slot], JAR_Y)
	jar.set_meta("slot", slot)
	jar.z_index = 5
	_world.add_child(jar)
	_jars.append(jar)
	if animate:
		jar.position.y = -260.0
		create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT) \
			.tween_property(jar, "position:y", JAR_Y, 0.45)
		for i in _tray.size():
			if _tray[i] != null and _tray[i].color_name == jar.color_name and jar.free_slots() > 0:
				_fly_tray_to_jar(i, jar)


func _process(_delta: float) -> void:
	for plate: Piece in _plates.duplicate():
		if plate.global_position.y > 2800.0 + _world.position.y:
			_plates.erase(plate)
			plate.queue_free()
			continue
		if plate.released and not plate.has_meta("fading"):
			plate.set_meta("fading", true)
			_gfx.shake(7.0, 0.2)
			AudioManager.play_sfx("thud", 0.05)
			_gfx.burst(plate.global_position, Color.WHITE)
			var tw := plate.create_tween()  # bound to the piece: it dies with it if the piece falls off screen first
			tw.tween_interval(1.6)
			tw.tween_property(plate, "modulate:a", 0.0, 0.4)
			tw.tween_callback(func() -> void:
				_plates.erase(plate)
				plate.queue_free())
	var moving := _cover_dirty
	for plate: Piece in _plates:
		if not plate.freeze and not plate.screws.is_empty():
			moving = true
	if not moving:
		return
	_cover_dirty = false
	for plate: Piece in _plates:
		for screw in plate.screws:
			var covered := _is_covered(screw)
			screw.modulate = Color(0.62, 0.6, 0.72) if covered else Color.WHITE
			if covered and screw.is_in_group("tappable"):
				screw.remove_from_group("tappable")
			elif not covered and not screw.is_in_group("tappable"):
				screw.add_to_group("tappable")


func _is_covered(screw: Screw) -> bool:
	for other in _plates:
		if other.plane > screw.plate.plane and not other.screws.is_empty() and other.covers(screw.global_position):
			return true
	return false


func _unhandled_input(event: InputEvent) -> void:
	if _over or get_tree().paused:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var at: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * event.position
		var best: Screw = null
		var best_d := TAP_RADIUS
		for s: Screw in get_tree().get_nodes_in_group("tappable"):
			var d := s.global_position.distance_to(at)
			if d < best_d:
				best_d = d
				best = s
		if best != null:
			_take(best)
			return
		for plate: Piece in _plates:   # a tap on a screw that is still covered is a mistake
			for s in plate.screws:
				if s.global_position.distance_to(at) < TAP_RADIUS:
					_mistake(s)
					return


func _take(screw: Screw) -> void:
	var jar := _jar_with_space(screw.color_name)
	var tray_slot := -1
	if jar == null:
		tray_slot = _tray.find(null)
		if tray_slot < 0:
			_reject(screw)
			return
	screw.plate.detach(screw)
	if is_instance_valid(_hint_ring):
		_hint_ring.queue_free()
	_cover_dirty = true
	screw.remove_from_group("tappable")
	screw.modulate = Color.WHITE
	screw.reparent(_fx, true)
	screw.z_index = 100
	_moves += 1
	_busy += 1
	_combo = _combo + 1 if jar != null else 0
	if COMBO_WORDS.has(_combo):
		_gfx.popup(COMBO_WORDS[_combo], screw.global_position + Vector2(0, -90), Levels.COLORS[screw.color_name].lightened(0.15))
		Haptics.heavy()
	AudioManager.play_sfx("unscrew", 0.02, minf(1.0 + _combo * 0.07, 1.9))
	Haptics.tap()
	var tw := create_tween()
	tw.tween_property(screw, "scale", Vector2.ONE * 1.35, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(screw, "rotation", screw.rotation + TAU, 0.14)
	if jar != null:
		var slot := jar.reserve()
		_fly(tw, screw, jar.slot_position(slot), 0.5)
		tw.tween_callback(_land_in_jar.bind(screw, jar, slot))
	else:
		_tray[tray_slot] = screw
		_fly(tw, screw, Vector2(_tray_xs[tray_slot], TRAY_Y), 1.0)
		tw.tween_callback(_land_in_tray)


func _fly(tw: Tween, screw: Screw, target: Vector2, end_scale: float) -> void:
	tw.tween_property(screw, "global_position", target, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(screw, "scale", Vector2.ONE * end_scale, 0.42)
	tw.parallel().tween_property(screw, "rotation", screw.rotation + TAU * 2.0, 0.42)


func _land_in_tray() -> void:
	_busy -= 1
	AudioManager.play_sfx("land", 0.03, 0.8)
	_tray_peak = maxi(_tray_peak, _tray.size() - _tray.count(null))
	_check_end()


func _land_in_jar(screw: Screw, jar: Jar, slot: int) -> void:
	_busy -= 1
	screw.rotation = 0.0
	screw.z_index = 0
	var full := jar.land(screw, slot)
	screw.scale = Vector2.ONE * 0.7
	create_tween().tween_property(screw, "scale", Vector2.ONE * 0.5, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	AudioManager.play_sfx("land", 0.02, minf(1.0 + jar.heads.size() * 0.18, 1.6))
	_gfx.burst(screw.global_position, screw.color)
	_filled += 1
	_set_progress(float(_filled) / _total)
	if full:
		_complete_jar(jar)
	else:
		_check_end()


func _fly_tray_to_jar(tray_slot: int, jar: Jar) -> void:
	var screw := _tray[tray_slot]
	_tray[tray_slot] = null
	var slot := jar.reserve()
	_busy += 1
	var tw := create_tween()
	_fly(tw, screw, jar.slot_position(slot), 0.5)
	tw.tween_callback(_land_in_jar.bind(screw, jar, slot))


func _complete_jar(jar: Jar) -> void:
	_busy += 1
	_remaining -= 3
	var slot: int = jar.get_meta("slot")
	_jars.erase(jar)
	AudioManager.play_sfx("jar_done", 0.0, minf(1.0 + _combo * 0.02, 1.3))
	Haptics.heavy()
	_gfx.burst(jar.global_position, Levels.COLORS[jar.color_name])
	_gfx.confetti(jar.global_position, 30)
	_gfx.shake(9.0)
	_gfx.popup("+3", jar.global_position + Vector2(0, 120), Color.WHITE, 72)
	var tw := create_tween()
	tw.tween_property(jar, "scale", Vector2.ONE * 1.15, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(jar, "scale", Vector2.ZERO, 0.18)
	tw.tween_callback(func() -> void:
		jar.queue_free()
		_busy -= 1
		_open_jar(slot)
		_check_end())


func _jar_with_space(color_name: String) -> Jar:
	for jar in _jars:
		if jar.color_name == color_name and jar.free_slots() > 0:
			return jar
	return null


func _reject(screw: Screw) -> void:
	_mistake(screw)


## A wrong tap (covered screw, or nowhere to put the screw) costs a life.
func _mistake(screw: Screw) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_mistake < 0.45 or _over:
		return
	_last_mistake = now
	_combo = 0
	var lives_left := _lives_view.lose()
	AudioManager.play_sfx("mistake")
	Haptics.heavy()
	_gfx.shake(10.0, 0.3)
	_gfx.flash(Color("FF5E73"))
	var tw := create_tween()
	var base := screw.position
	for i in 3:
		tw.tween_property(screw, "position:x", base.x + 10.0, 0.04)
		tw.tween_property(screw, "position:x", base.x - 10.0, 0.04)
	tw.tween_property(screw, "position:x", base.x, 0.04)
	_gfx.heart_break(screw.global_position + Vector2(0, -70))
	if lives_left <= 0:
		_busy = 0
		_end(false, "Out of Lives!")


## Hint button with a counter badge, bottom right.
func _build_hint_button() -> void:
	var b := IconButton.new()
	b.glyph = load("res://assets/art/icons/hint.png")
	b.group_name = "btn_hint"
	b.button_size = 170.0
	b.glyph_size = 130
	b.position = Vector2(get_viewport_rect().size.x - 230.0, TRAY_Y - 85.0 + (get_viewport_rect().size.y - 1920.0) / 2.0)
	b.z_index = 160
	add_child(b)
	b.pressed.connect(_hint)
	_hint_button = b
	_hint_badge = Label.new()
	_hint_badge.text = str(_hints_left)
	_hint_badge.add_theme_font_size_override("font_size", 56)
	_hint_badge.position = Vector2(112, 96)
	_hint_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(_hint_badge)


## The live position in the solver's terms (alive screws, pieces' remaining screws, jars incl. reserved slots, queue index, tray).
func _live_state() -> Dictionary:
	var alive := 0
	var alive_count := 0
	for i in _all_screws.size():
		if is_instance_valid(_all_screws[i]) and _all_screws[i].plate != null:
			alive |= 1 << i
			alive_count += 1
	var left := PackedInt32Array()
	for p in _pieces_all:
		left.append(p.screws.size())
	var jars: Array = []
	var held := 0
	for jar in _jars:
		var n := 3 - jar.free_slots()
		jars.append([jar.color_name, n])
		held += n
	var tray := {}
	for t in _tray:
		if t != null:
			tray[t.color_name] = tray.get(t.color_name, 0) + 1
			held += 1
	return {"alive": alive, "left": left, "jars": jars, "qi": _total_jars - _queue.size(), "tray": tray,
		"remaining": alive_count + held}


## Test hook: how long the hint search takes from the current position (prints, uses no hint).
func debug_hint_report() -> void:
	var t := Time.get_ticks_msec()
	var res := Figure.solve(_data, _analysis, HINT_NODE_LIMIT, _live_state())
	print("[hint] level ", level_index + 1, " solved=", res["solved"], " nodes=", res["nodes"], " ms=", Time.get_ticks_msec() - t, " busy=", _busy)


## Hint: solve the live position with the level solver and ring the first screw of a winning order.
func _hint() -> void:
	if _over or get_tree().paused:
		return
	if _hints_left <= 0:
		_earn_hint()
		return
	if _busy > 0:   # a screw is still flying: remember the request and answer when everything has settled
		_hint_pending = true
		return
	_hint_pending = false
	var res := Figure.solve(_data, _analysis, HINT_NODE_LIMIT, _live_state())
	if not res["solved"] or res["path"].is_empty():
		_gfx.popup("Stuck! Restart", Vector2(540, 1480), Color("FF5E73"), 80)
		_gfx.shake(8.0)
		return
	_hints_left -= 1
	_hint_badge.text = str(_hints_left) if _hints_left > 0 else "+"
	Analytics.log_event("hint_used", {"level": level_index + 1})
	AudioManager.play_sfx("star", 0.0, 1.3)
	var target: Screw = _all_screws[res["path"][0]]
	_show_hint(target)


## Out of free hints: the badge shows "+" and a tap offers one more for watching a rewarded ad.
func _earn_hint() -> void:
	if _hint_earning:
		return
	if not Ads.is_rewarded_ready():
		_gfx.popup("No ad ready", Vector2(540, 1480), Color("FFC93C"), 72)
		return
	_hint_earning = true
	var granted: bool = await Ads.show_rewarded()
	_hint_earning = false
	Analytics.log_event("rewarded_hint", {"level": level_index + 1, "granted": granted})
	if granted and is_instance_valid(_hint_badge):
		_hints_left += 1
		_hint_badge.text = str(_hints_left)
		_gfx.popup("+1 hint", Vector2(540, 1480), Color("7BE495"), 72)


func _show_hint(target: Screw) -> void:
	if is_instance_valid(_hint_ring):
		_hint_ring.queue_free()
	var ring := Node2D.new()
	ring.z_index = 190
	ring.global_position = target.global_position
	ring.draw.connect(func() -> void:
		ring.draw_arc(Vector2.ZERO, Screw.R + 16.0, 0.0, TAU, 40, Color(OUTLINE, 0.95), 16.0, true)
		ring.draw_arc(Vector2.ZERO, Screw.R + 16.0, 0.0, TAU, 40, Color("FFC93C"), 10.0, true)
		ring.draw_arc(Vector2.ZERO, Screw.R + 34.0, 0.0, TAU, 40, Color("FFC93C", 0.5), 6.0, true))
	_fx.add_child(ring)
	_hint_ring = ring
	var tw := ring.create_tween().set_loops()   # stays until the player takes a screw
	tw.tween_property(ring, "scale", Vector2.ONE * 1.3, 0.4).set_trans(Tween.TRANS_SINE)
	tw.tween_property(ring, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_SINE)
	var bob := target.create_tween().set_loops(6)
	bob.tween_property(target, "scale", Vector2.ONE * 1.25, 0.25)
	bob.tween_property(target, "scale", Vector2.ONE, 0.25)


## Test hook: taps a covered screw, like a player's mistake.
func debug_mistake() -> void:
	for plate: Piece in _plates:
		for s in plate.screws:
			if _is_covered(s):
				_mistake(s)
				return


## Test hook (playtest `call` step): takes one screw like a sensible player would, preferring screws that fit a jar.
func autoplay_step() -> void:
	if _over or _busy > 1:
		return
	var best: Screw = null
	for s: Screw in get_tree().get_nodes_in_group("tappable"):
		if _jar_with_space(s.color_name) != null:
			best = s
			break
	if best == null and _tray.has(null):
		best = get_tree().get_first_node_in_group("tappable")
	if best != null:
		_take(best)


## Called whenever something finished moving: decides win or loss.
func _check_end() -> void:
	if _over or _busy > 0:
		return
	if _hint_pending:
		_hint()
	if _remaining <= 0:
		_end(true)
	elif not _tray.has(null) and not _has_move():
		_end(false)


func _has_move() -> bool:
	for plate in _plates:
		for screw in plate.screws:
			if not _is_covered(screw) and _jar_with_space(screw.color_name) != null:
				return true
	return false


func _end(win: bool, fail_title := "Tray Full!") -> void:
	_over = true
	Analytics.log_event("level_end", {"level_name": str(level_index + 1), "success": win, "hints_left": _hints_left, "lives": _lives_view.lives})
	await get_tree().create_timer(0.5 if win else 0.3).timeout
	if win:
		_gfx.confetti(Vector2(540, -40) - _world.position * 0, 90, true)
		AudioManager.play_sfx("win")
		await get_tree().create_timer(0.9).timeout
	var overlay := GAME_OVER.instantiate()
	overlay.z_index = 300
	add_child(overlay)
	overlay.menu_scene = LEVEL_MAP
	overlay.score_label = "Moves"
	if win:
		var stars := 3 if _tray_peak <= 1 else (2 if _tray_peak <= (_tray_xs.size() + 1) / 2 else 1)
		stars = mini(stars, _lives_view.lives)   # every lost life caps the rating
		var all: Dictionary = Settings.get_value("stars").duplicate()
		all[str(level_index)] = maxi(int(all.get(str(level_index), 0)), stars)
		Settings.set_value("stars", all)
		Settings.set_value("level_unlocked", maxi(Settings.get_value("level_unlocked"), level_index + 2))
		var next := func() -> void:
			if Ads.try_interstitial(level_index + 1) and not Ads.is_mock():
				await Ads.ad_finished
			level_index += 1
			SceneTransition.reload()
		overlay.show_result(_moves, "Level Clear!", next if level_index + 1 < Levels.DATA.size() else Callable(), stars)
	else:
		overlay.show_result(_moves, fail_title)
