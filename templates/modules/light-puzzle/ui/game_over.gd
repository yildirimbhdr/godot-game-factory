extends Control
## Instance, add to the game scene, then call show_result(score).

## Where the menu button leads and what it says (e.g. a level map instead of the main menu).
var menu_scene := SceneTransition.MAIN_MENU_SCENE
var menu_text := "Main Menu"
var score_label := "Score"

@onready var _panel: Control = %Panel


func _ready() -> void:
	%RetryButton.pressed.connect(SceneTransition.reload)
	%MenuButton.pressed.connect(func() -> void: SceneTransition.change_scene(menu_scene))


## `title` replaces "Game Over" (e.g. "Level Clear!"); a valid `next` callable shows a "Next" button that calls it.
func show_result(score: int, title := "Game Over", next := Callable(), stars := -1, best_text := "", extra := {}) -> void:
	%Title.text = title
	%MenuButton.text = menu_text
	%MenuButton.glyph = "levels" if menu_scene == SceneTransition.LEVEL_SELECT_SCENE else "home"
	if next.is_valid():
		%NextButton.visible = true
		%NextButton.pressed.connect(next)
	PauseManager.set_gameplay_active(false)
	var best: int = Settings.get_value("best_score")
	var is_new_best := score > best and stars < 0
	if is_new_best:
		best = score
		Settings.set_value("best_score", best)
	%ScoreLabel.text = "%s %d" % [tr(score_label), score]
	%RetryButton.text = "Retry" if not next.is_valid() else "Replay"
	%BestLabel.text = tr("New best!") if is_new_best else tr("Best %d") % best
	if best_text != "":
		%BestLabel.text = best_text
	var row: StarRow
	if not extra.is_empty():
		_decorate(extra, stars, score)
	if stars >= 0:
		row = StarRow.make(stars)
		var column: VBoxContainer = $Center/Panel/Column
		column.add_child(row)
		column.move_child(row, %Title.get_index() + 1)
	else:
		AudioManager.play_sfx("game_over")
	Haptics.heavy()
	await get_tree().process_frame
	_panel.pivot_offset = _panel.size / 2.0
	_panel.scale = Vector2.ONE * 0.8
	_panel.modulate.a = 0.0
	var t := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(_panel, "scale", Vector2.ONE, 0.35)
	t.tween_property(_panel, "modulate:a", 1.0, 0.2)
	if row:
		await get_tree().create_timer(0.35).timeout
		row.show_stars(stars, 0.0 if _no_fx() else 1.0)


func _no_fx() -> bool:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--playtest="):
			return true
	return false


const LOGO := preload("res://assets/art/logo.png")


## Level-clear dressing: world-coloured frame with glow, floating gem, world progress pips, count-up, badges, one shine sweep.
func _decorate(extra: Dictionary, stars: int, moves: int) -> void:
	var accent: Color = extra.get("accent", Color("B8C4FF"))
	var calm := _no_fx()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.085, 0.105, 0.25, 0.97)
	style.border_color = accent
	style.set_border_width_all(4)
	style.set_corner_radius_all(48)
	style.shadow_color = Color(accent, 0.35)
	style.shadow_size = 46
	style.set_content_margin_all(44)
	_panel.add_theme_stylebox_override("panel", style)
	_panel.clip_contents = true
	%Title.add_theme_color_override("font_outline_color", accent.darkened(0.55))
	%Title.add_theme_constant_override("outline_size", 12)
	%Title.add_theme_color_override("font_color", accent.lightened(0.55))
	if not calm:
		%Title.pivot_offset = Vector2(400, 60)
		%Title.scale = Vector2.ONE * 0.5
		create_tween().tween_property(%Title, "scale", Vector2.ONE, 0.6).set_delay(0.15).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	var column: VBoxContainer = $Center/Panel/Column
	var logo := TextureRect.new()
	logo.texture = LOGO
	logo.custom_minimum_size = Vector2(300, 240)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	column.add_child(logo)
	column.move_child(logo, 0)
	if not calm:
		var bob := logo.create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		bob.tween_property(logo, "position:y", -10.0, 1.0).as_relative()
		bob.tween_property(logo, "position:y", 10.0, 1.0).as_relative()
	var sub := Label.new()
	sub.text = "%s  -  %d / %d" % [extra.get("world_name", ""), int(extra.get("level_in_world", 1)), Levels.LEVELS_PER_WORLD]
	sub.add_theme_color_override("font_color", accent)
	sub.add_theme_font_size_override("font_size", 40)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(sub)
	column.move_child(sub, %Title.get_index() + 1)
	var pips := WorldProgress.new().setup(int(extra.get("world_first", 0)), int(extra.get("level_index", 0)), accent, not calm)
	column.add_child(pips)
	column.move_child(pips, %BestLabel.get_index() + 1)
	var badges: Array[String] = []
	if bool(extra.get("improved", false)):
		badges.append(tr("New best!"))
	if stars == 3:
		badges.append(tr("Perfect!"))
	if not badges.is_empty():
		var pill := PanelContainer.new()
		var ps := StyleBoxFlat.new()
		ps.bg_color = Color(accent, 0.22)
		ps.border_color = accent
		ps.set_border_width_all(3)
		ps.set_corner_radius_all(40)
		ps.set_content_margin_all(14)
		ps.content_margin_left = 34
		ps.content_margin_right = 34
		pill.add_theme_stylebox_override("panel", ps)
		pill.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var tag := Label.new()
		tag.text = "  -  ".join(badges)
		tag.add_theme_font_size_override("font_size", 44)
		tag.add_theme_color_override("font_color", Color("FFD166"))
		pill.add_child(tag)
		column.add_child(pill)
		column.move_child(pill, %BestLabel.get_index() + 1)
		if not calm:
			pill.scale = Vector2.ZERO
			pill.pivot_offset = Vector2(300, 30)
			create_tween().tween_property(pill, "scale", Vector2.ONE, 0.45).set_delay(0.9).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if not calm:
		var label: Label = %ScoreLabel
		var count := create_tween()
		count.tween_method(func(v: float) -> void: label.text = "%s %d" % [tr(score_label), int(round(v))], 0.0, float(moves), 0.5).set_delay(0.3)
		var shine := Shine.new()
		shine.accent = accent
		_panel.add_child(shine)


## One diagonal highlight that sweeps across the panel when it appears.
class Shine extends Control:
	var accent := Color.WHITE
	var _x := -0.3

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		create_tween().tween_method(func(v: float) -> void:
			_x = v
			queue_redraw(), -0.3, 1.3, 0.9).set_delay(0.35)

	func _draw() -> void:
		var w := size.x * 0.16
		var x := size.x * _x
		draw_colored_polygon(PackedVector2Array([Vector2(x, 0), Vector2(x + w, 0), Vector2(x + w - size.y * 0.25, size.y), Vector2(x - size.y * 0.25, size.y)]), Color(1, 1, 1, 0.10))
