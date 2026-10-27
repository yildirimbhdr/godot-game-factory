extends Control
## Level select: worlds of 10 levels in a grid, locked / open / cleared states with stars, saved progress.

const COLUMNS := 5
const CELL := Vector2(176, 210)

@onready var _content: VBoxContainer = %Content
@onready var _scroll: ScrollContainer = %Scroll

var _current_cell: Control
var _pop_cell: LevelCell


func _ready() -> void:
	$Background.dim = 0.5
	$Background.texture = load("res://assets/art/bg_world1.jpg")
	PauseManager.set_gameplay_active(false)
	%HomeButton.pressed.connect(func() -> void: SceneTransition.change_scene(SceneTransition.MAIN_MENU_SCENE))
	_build()


func _build() -> void:
	var count := Levels.DATA.size()
	var unlocked: int = clampi(int(Settings.get_value("level_unlocked", 1)), 1, count)
	var stars: Dictionary = Settings.get_value("stars", {})
	var total := 0
	for v: Variant in stars.values():
		total += int(v)
	%StarTotal.text = "%d / %d" % [total, count * 3]
	for w in count / Levels.LEVELS_PER_WORLD:
		var banner := Label.new()
		banner.text = "%d. %s" % [w + 1, tr(Levels.WORLD_NAMES[w])]
		banner.add_theme_font_size_override("font_size", 60)
		banner.add_theme_color_override("font_color", Levels.WORLD_COLORS[w])
		_content.add_child(banner)
		var grid := GridContainer.new()
		grid.columns = COLUMNS
		grid.add_theme_constant_override("h_separation", 12)
		grid.add_theme_constant_override("v_separation", 16)
		_content.add_child(grid)
		for k in Levels.LEVELS_PER_WORLD:
			var i := w * Levels.LEVELS_PER_WORLD + k
			var cell := LevelCell.new().setup(i, Levels.WORLD_COLORS[w], i + 1 > unlocked, int(stars.get(str(i), 0)), i + 1 == unlocked)
			cell.custom_minimum_size = CELL
			cell.chosen.connect(_play)
			cell.add_to_group("level_cell")
			grid.add_child(cell)
			if i + 1 == unlocked:
				_current_cell = cell
			if i == int(Settings.get_value("just_unlocked", -1)):
				_pop_cell = cell
		var gap := Control.new()
		gap.custom_minimum_size.y = 40
		_content.add_child(gap)
	await get_tree().process_frame
	await get_tree().process_frame
	if _pop_cell and not _no_fx():
		Settings.set_value("just_unlocked", -1)
		_pop_cell.play_unlock()
		AudioManager.play_sfx("star", 0.0, 1.3)
		Haptics.tap()
	if _current_cell:
		_scroll.scroll_vertical = int(maxf(0.0, _current_cell.global_position.y - _scroll.global_position.y + _scroll.scroll_vertical - _scroll.size.y * 0.4))


func _no_fx() -> bool:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--playtest="):
			return true
	return false


func _play(index: int, locked: bool) -> void:
	if locked:
		AudioManager.play_sfx("locked")
		Haptics.tap()
		return
	Game.level_index = index
	SceneTransition.change_scene(SceneTransition.GAME_SCENE)


class LevelCell extends Control:
	signal chosen(index: int, locked: bool)

	const R := 22.0
	var index := 0
	var tint := Color.WHITE
	var locked := false
	var current := false
	var star_row: StarRow
	var _label: Label
	var _pulse := 0.0
	var _ring := 1.0

	func setup(i: int, color: Color, is_locked: bool, star_count: int, is_current: bool) -> LevelCell:
		index = i
		tint = color
		locked = is_locked
		current = is_current
		_label = Label.new()
		_label.text = "" if locked else str(i + 1)
		_label.add_theme_font_size_override("font_size", 64)
		_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		_label.offset_bottom = -40
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_label)
		if not locked:
			star_row = StarRow.make(star_count, true)
			star_row.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
			star_row.position = Vector2(0, 0)
			add_child(star_row)
			star_row.anchor_left = 0.5
			star_row.anchor_right = 0.5
			star_row.anchor_top = 1.0
			star_row.anchor_bottom = 1.0
			star_row.offset_left = -45
			star_row.offset_right = 45
			star_row.offset_top = -50
			star_row.offset_bottom = -20
		if current:
			var t := create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			t.tween_property(self, "_pulse", 1.0, 0.9)
			t.tween_property(self, "_pulse", 0.0, 0.9)
		return self

	## Newly unlocked level: pop in with a bounce and an expanding ring.
	func play_unlock() -> void:
		pivot_offset = size / 2.0
		scale = Vector2.ONE * 0.4
		modulate.a = 0.0
		var t := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(self, "scale", Vector2.ONE, 0.5)
		t.tween_property(self, "modulate:a", 1.0, 0.25)
		_ring = 0.0
		create_tween().tween_property(self, "_ring", 1.0, 0.7)

	func _process(_delta: float) -> void:
		if current or _ring < 1.0:
			queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			chosen.emit(index, locked)
			accept_event()

	func _draw() -> void:
		var r := Rect2(Vector2(6, 6), size - Vector2(12, 12))
		var s := StyleBoxFlat.new()
		s.set_corner_radius_all(int(R))
		if locked:
			s.bg_color = Color("151A38")
			s.border_color = Color("232B52")
		else:
			s.bg_color = Color("232B52")
			s.border_color = tint
			s.shadow_color = Color(tint, 0.25 + 0.25 * _pulse)
			s.shadow_size = 10 + int(10 * _pulse)
		s.set_border_width_all(4 if not locked else 2)
		s.draw(get_canvas_item(), r)
		if _ring < 1.0:
			draw_arc(size / 2.0, 70.0 + _ring * 90.0, 0, TAU, 48, Color(tint, 1.0 - _ring), 8.0, true)
		if locked:
			var c := size / 2.0
			draw_rect(Rect2(c + Vector2(-22, -4), Vector2(44, 36)), Color("39426F"), true)
			draw_arc(c + Vector2(0, -4), 16, PI, TAU, 16, Color("39426F"), 7.0, true)
