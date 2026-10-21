class_name GameFx
extends Node
## Reusable "juice": floating words, camera shake, confetti, particle bursts, a screen flash and a breaking heart.
## Add as a child of the game scene, then call setup() once.
##
##   gfx.setup(fx_root, camera, {"mint": Color(...), ...}, outline_color)
##   gfx.popup("Nice!", at)          floating word            gfx.shake(8.0)           camera shake
##   gfx.burst(at, color)            small sparkle burst      gfx.confetti(at, 40)     multi-colour confetti
##   gfx.confetti(top, 90, true)     confetti rain            gfx.flash(Color.RED)     full-screen flash
##   gfx.heart_break(at)             heart splits and falls
## Never shake by moving a node that parents physics bodies; the camera offset is used on purpose (lesson 0015).
## Resources are built once here so effects never allocate in the hot moment.

var outline := Color("5B4B8A")

var _fx: Node2D
var _camera: Camera2D
var _palette: Dictionary = {}
var _spark_tex: GradientTexture2D
var _confetti_ramp: Gradient
var _flash: ColorRect


func setup(fx_root: Node2D, camera: Camera2D, palette: Dictionary, outline_color := Color("5B4B8A")) -> void:
	_fx = fx_root
	_camera = camera
	_palette = palette
	outline = outline_color
	_spark_tex = GradientTexture2D.new()
	_spark_tex.fill = GradientTexture2D.FILL_RADIAL
	_spark_tex.fill_from = Vector2(0.5, 0.5)
	_spark_tex.fill_to = Vector2(1.0, 0.5)
	_spark_tex.width = 32
	_spark_tex.height = 32
	_spark_tex.gradient = Gradient.new()
	_spark_tex.gradient.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	_confetti_ramp = Gradient.new()
	var keys := palette.keys()
	var cols := PackedColorArray()
	var offs := PackedFloat32Array()
	for i in keys.size():
		cols.append(palette[keys[i]])
		offs.append(i / float(maxi(keys.size() - 1, 1)))
	_confetti_ramp.colors = cols
	_confetti_ramp.offsets = offs
	var layer := CanvasLayer.new()
	layer.layer = 90
	add_child(layer)
	_flash = ColorRect.new()
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.modulate.a = 0.0
	layer.add_child(_flash)


func flash(color: Color, alpha := 0.35, duration := 0.35) -> void:
	_flash.color = color
	_flash.modulate.a = alpha
	create_tween().tween_property(_flash, "modulate:a", 0.0, duration)


## Floating word that pops up and fades (combo praise, score pops).
func popup(text: String, at: Vector2, color := Color.WHITE, font_size := 84) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.custom_minimum_size = Vector2(500, 0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = at - Vector2(250, 60)
	label.pivot_offset = Vector2(250, 60)
	label.scale = Vector2.ZERO
	label.z_index = 220
	_fx.add_child(label)
	var tw := label.create_tween().set_parallel(true)
	tw.tween_property(label, "scale", Vector2.ONE * 1.15, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(label, "position:y", label.position.y - 140.0, 0.95)
	tw.tween_property(label, "modulate:a", 0.0, 0.3).set_delay(0.65)
	tw.chain().tween_callback(label.queue_free)


func shake(strength: float, duration := 0.28) -> void:
	var tw := create_tween()
	var steps := 6
	for i in steps:
		var fade := 1.0 - float(i) / steps
		tw.tween_property(_camera, "offset", Vector2(randf_range(-1, 1), randf_range(-1, 1)) * strength * fade, duration / steps)
	tw.tween_property(_camera, "offset", Vector2.ZERO, 0.04)


## Multi-colour confetti burst (`rain` spreads it over the top edge and drops it).
func confetti(at: Vector2, count := 36, rain := false) -> void:
	var p := CPUParticles2D.new()
	p.color_initial_ramp = _confetti_ramp
	p.amount = count
	p.one_shot = true
	p.explosiveness = 0.0 if rain else 0.95
	p.lifetime = 2.2 if rain else 1.1
	p.global_position = at
	p.z_index = 230
	p.scale_amount_min = 7.0
	p.scale_amount_max = 14.0
	p.angular_velocity_min = -400.0
	p.angular_velocity_max = 400.0
	p.gravity = Vector2(0, 900)
	if rain:
		p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		p.emission_rect_extents = Vector2(540, 10)
		p.direction = Vector2(0, 1)
		p.spread = 25.0
		p.initial_velocity_min = 250.0
		p.initial_velocity_max = 600.0
	else:
		p.direction = Vector2(0, -1)
		p.spread = 70.0
		p.initial_velocity_min = 500.0
		p.initial_velocity_max = 950.0
	_fx.add_child(p)
	p.emitting = true
	get_tree().create_timer(3.0).timeout.connect(p.queue_free)


## Small round-particle burst (landing sparkle, dust).
func burst(at: Vector2, color: Color) -> void:
	var p := CPUParticles2D.new()
	p.texture = _spark_tex
	p.global_position = at
	p.amount = 22
	p.lifetime = 0.7
	p.one_shot = true
	p.explosiveness = 1.0
	p.spread = 180.0
	p.initial_velocity_min = 260.0
	p.initial_velocity_max = 520.0
	p.gravity = Vector2(0, 900)
	p.scale_amount_min = 0.8
	p.scale_amount_max = 1.8
	p.color = color
	p.z_index = 150
	_fx.add_child(p)
	p.emitting = true
	get_tree().create_timer(1.2).timeout.connect(p.queue_free)


## Half-width of the heart outline at height y (lower half only: y grows with the index there).
func _heart_width(pts: PackedVector2Array, y: float) -> float:
	for i in range(10, 20):
		if pts[i].y <= y and pts[i + 1].y >= y:
			var f := (y - pts[i].y) / maxf(pts[i + 1].y - pts[i].y, 0.001)
			return lerpf(pts[i].x, pts[i + 1].x, f)
	return 4.0


## A heart that splits in two and falls away: shown where the mistake happened instead of text.
func heart_break(at: Vector2) -> void:
	var pts := PackedVector2Array()
	for i in 40:
		var t := TAU * i / 40.0
		pts.append(Vector2(16.0 * pow(sin(t), 3.0), -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))) * 3.2)
	for side in [-1, 1]:
		var half := Node2D.new()
		half.position = at
		half.z_index = 240
		_fx.add_child(half)
		var poly := PackedVector2Array()
		var mid: Array[Vector2] = []   # jagged crack, bottom to top, always inside the heart
		var wobble := [0.15, 0.55, 0.12, 0.6]
		for k in 4:
			var cy := 46.0 - k * 14.0
			mid.append(Vector2(side * _heart_width(pts, cy) * wobble[k], cy))
		if side == 1:   # right half: top-centre down the right edge to the bottom, then up the crack
			for i in range(0, 21):
				poly.append(pts[i])
			poly.append_array(PackedVector2Array(mid))
		else:           # left half: bottom up the left edge to the top, then down the crack
			for i in range(20, 40):
				poly.append(pts[i])
			poly.append(pts[0])
			mid.reverse()
			poly.append_array(PackedVector2Array(mid))
		half.draw.connect(func() -> void:
			half.draw_colored_polygon(poly, Color("FF5E73"))
			var closed := poly.duplicate()
			closed.append(poly[0])
			half.draw_polyline(closed, outline, 6.0, true))
		half.queue_redraw()
		half.scale = Vector2.ZERO
		var tw := half.create_tween().set_parallel(true)
		tw.tween_property(half, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(half, "position", at + Vector2(side * 70.0, 160.0), 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).set_delay(0.12)
		tw.tween_property(half, "rotation", side * 0.9, 0.8).set_delay(0.12)
		tw.tween_property(half, "modulate:a", 0.0, 0.3).set_delay(0.65)
		tw.chain().tween_callback(half.queue_free)
