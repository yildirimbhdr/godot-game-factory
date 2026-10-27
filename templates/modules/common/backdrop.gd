class_name Backdrop
extends Control
## Deep-navy gradient with faint light specks drifting upward. Add as the first child of any screen.

const TOP := Color("0B0E22")
const BOTTOM := Color("171E48")
const SPECK_COLORS: Array[Color] = [Color("B8C4FF"), Color("5DE0E6"), Color("FF4D6D"), Color("FFD166")]
const COUNT := 26

## Optional image drawn instead of the gradient (scaled to cover the screen).
## How much the image is darkened so content on top stays readable.
var dim := 0.28
var texture: Texture2D:
	set(v):
		texture = v
		queue_redraw()
var _specks: Array[Dictionary] = []
var _gradient: GradientTexture2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var g := Gradient.new()
	g.colors = PackedColorArray([TOP, BOTTOM])
	_gradient = GradientTexture2D.new()
	_gradient.gradient = g
	_gradient.fill_from = Vector2(0, 0)
	_gradient.fill_to = Vector2(0, 1)
	_gradient.width = 4
	_gradient.height = 256
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in COUNT:
		_specks.append({"p": Vector2(rng.randf(), rng.randf()), "r": rng.randf_range(2.5, 7.0), "v": rng.randf_range(0.004, 0.012),
			"c": SPECK_COLORS[i % SPECK_COLORS.size()], "a": rng.randf_range(0.10, 0.28)})
	var reduced := false
	for arg in OS.get_cmdline_user_args():
		reduced = reduced or arg.begins_with("--playtest=")   # static frames in playtests (lesson 0027)
	set_process(not reduced)


func _process(delta: float) -> void:
	for s in _specks:
		var p: Vector2 = s.p
		p.y -= float(s.v) * delta
		if p.y < -0.02:
			p.y = 1.02
		s.p = p
	queue_redraw()


func _draw() -> void:
	if texture:
		var k := maxf(size.x / texture.get_width(), size.y / texture.get_height())
		var drawn := Vector2(texture.get_size()) * k
		draw_texture_rect(texture, Rect2((size - drawn) / 2.0, drawn), false)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.03, 0.04, 0.09, dim))   # keeps the board readable
	else:
		draw_texture_rect(_gradient, Rect2(Vector2.ZERO, size), false)
	for s in _specks:
		var p: Vector2 = (s.p as Vector2) * size
		var c: Color = s.c
		draw_circle(p, float(s.r) * 3.0, Color(c, float(s.a) * 0.25))
		draw_circle(p, float(s.r), Color(c, float(s.a)))
