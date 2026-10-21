class_name LevelNode
extends Control
## One stop on the level map, drawn as a big screw head: coloured when playable, a star when cleared,
## grey with a padlock when locked.

signal chosen(index: int)

const OUTLINE := Color("5B4B8A")
const R := 78.0

var index := 0
var locked := false
var done := false
var stars := 0
var current := false
var tint := Color.WHITE
var _label: Label
var _ring := 0.0


func setup(i: int, color: Color, is_locked: bool, is_done: bool, is_current: bool, star_count := 0) -> LevelNode:
	index = i
	stars = star_count
	tint = color
	locked = is_locked
	done = is_done
	current = is_current
	custom_minimum_size = Vector2(R * 2 + 40, R * 2 + 40)
	size = custom_minimum_size
	pivot_offset = size / 2.0
	_label = Label.new()
	_label.text = str(i + 1) if not locked else ""
	_label.add_theme_font_size_override("font_size", 78)
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	if current:
		var tw := create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(self, "_ring", 1.0, 0.8)
		tw.tween_property(self, "_ring", 0.0, 0.8)
		var bob := create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		bob.tween_property(self, "scale", Vector2.ONE * 1.1, 0.8)
		bob.tween_property(self, "scale", Vector2.ONE, 0.8)
	return self


func _process(_delta: float) -> void:
	if current:
		queue_redraw()


func _draw() -> void:
	var c := size / 2.0
	var base := tint if not locked else Color("C9C3D6")
	if current:
		draw_arc(c, R + 14.0 + _ring * 14.0, 0.0, TAU, 48, Color(tint, 0.55 * (1.0 - _ring)), 10.0, true)
	draw_circle(c + Vector2(0, 8), R, Color(OUTLINE, 0.3))
	draw_circle(c, R, base)
	draw_circle(c + Vector2(0, R * 0.2), R * 0.84, base.darkened(0.1))
	draw_circle(c + Vector2(0, -R * 0.06), R * 0.84, base)
	draw_arc(c, R, 0.0, TAU, 64, OUTLINE, 9.0, true)
	draw_arc(c, R * 0.68, deg_to_rad(205), deg_to_rad(265), 16, Color(1, 1, 1, 0.8), 8.0, true)
	if locked:
		var body := Rect2(c + Vector2(-26, -2), Vector2(52, 42))
		draw_arc(c + Vector2(0, -4), 18.0, PI, TAU, 16, OUTLINE, 9.0, true)
		draw_rect(body, OUTLINE)
		draw_circle(c + Vector2(0, 19), 6.0, Color("C9C3D6"))
	if done:
		var full: Texture2D = load("res://assets/art/icons/star.png")
		var empty: Texture2D = load("res://assets/art/icons/star_empty.png")
		for k in 3:
			var tex := full if k < stars else empty
			draw_texture_rect(tex, Rect2(c + Vector2(-78 + k * 54, R + 2), Vector2(50, 50)), false)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if locked:
			AudioManager.play_sfx("ui_click")
			var tw := create_tween()
			tw.tween_property(self, "rotation", 0.12, 0.05)
			tw.tween_property(self, "rotation", -0.12, 0.08)
			tw.tween_property(self, "rotation", 0.0, 0.05)
			return
		AudioManager.play_sfx("ui_click")
		Haptics.tap()
		chosen.emit(index)
