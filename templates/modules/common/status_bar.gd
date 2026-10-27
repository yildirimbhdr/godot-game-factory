class_name StatusBar
extends Control
## Pill under the HUD: world name, moves against par, and the three star goals that go dark as moves run out.

const STAR_ON := preload("res://assets/art/star_on.png")
const STAR_OFF := preload("res://assets/art/star_off.png")

var accent := Color("B8C4FF")
var world_name := ""
var moves := 0
var par := 1
var _star_scale: Array[float] = [1.0, 1.0, 1.0]
var _style := StyleBoxFlat.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style.bg_color = Color(0.07, 0.09, 0.2, 0.88)
	_style.set_border_width_all(3)
	_style.set_corner_radius_all(48)
	_style.shadow_size = 18
	_style.content_margin_left = 0


func setup(world: String, color: Color, level_par: int) -> void:
	world_name = world
	accent = color
	par = level_par
	set_moves(0)


func set_moves(count: int) -> void:
	var before := _lit()
	moves = count
	var after := _lit()
	for i in 3:
		var was: bool = before[i]
		var now: bool = after[i]
		if was != now:   # a star goal was lost or won back: it shrinks or pops
			var t := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			t.tween_method(_set_star.bind(i), 0.4 if not now else 1.4, 1.0, 0.35)
	queue_redraw()


func _lit() -> Array[bool]:
	return [true, moves <= par + 2, moves <= par]


func _set_star(v: float, i: int) -> void:
	_star_scale[i] = v
	queue_redraw()


func _draw() -> void:
	_style.border_color = Color(accent, 0.7)
	_style.shadow_color = Color(accent, 0.2)
	_style.draw(get_canvas_item(), Rect2(Vector2.ZERO, size))
	var font := get_theme_font("font", "Label")
	draw_string(font, Vector2(0, 38), world_name, HORIZONTAL_ALIGNMENT_CENTER, size.x, 30, Color(accent, 0.95))
	var line := tr("Moves %d / %d") % [moves, par]
	draw_string(font, Vector2(40, size.y - 26), line, HORIZONTAL_ALIGNMENT_LEFT, size.x * 0.55, 46, Color.WHITE)
	var lit := _lit()
	for i in 3:
		var c := Vector2(size.x - 190 + i * 64, size.y - 44)
		var px := 52.0 * _star_scale[i]
		draw_texture_rect(STAR_ON if lit[i] else STAR_OFF, Rect2(c - Vector2.ONE * px / 2.0, Vector2.ONE * px), false)
