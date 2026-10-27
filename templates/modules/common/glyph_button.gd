class_name GlyphButton
extends UIButton
## Square icon button with a procedurally drawn glyph (undo, restart, hint, home), so no icon files are needed.
## `badge` >= 0 shows a small counter in the corner (remaining hints).

@export var glyph := "undo"
## Short text drawn next to the glyph (a language code); the button text itself stays hidden.
var caption := "":
	set(v):
		caption = v
		queue_redraw()
var badge := -1:
	set(v):
		badge = v
		queue_redraw()

const INK := Color("FFFFFF")


func _ready() -> void:
	super()
	custom_minimum_size = Vector2(150, 150)
	clip_text = true   # hidden text must not widen the button
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	# the text stays (screen readers, playtests tap_text it) but is not drawn: the icon is the label
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color", "font_hover_pressed_color"]:
		add_theme_color_override(state, Color(0, 0, 0, 0))
	toggled.connect(func(_on: bool) -> void: queue_redraw())


func _draw() -> void:
	var c := size / 2.0
	var u := minf(size.x, size.y) / 2.0
	var col := INK if not disabled else Color(1, 1, 1, 0.35)
	var w := u * 0.11
	match glyph:
		"undo":
			_arrow_arc(c + Vector2(0, u * 0.08), u * 0.42, -PI * 1.1, 0.3, col, w, true)
		"restart":
			_arrow_arc(c, u * 0.42, -PI * 0.35, PI * 1.3, col, w, false)
		"hint":
			draw_arc(c + Vector2(0, -u * 0.12), u * 0.3, 0, TAU, 32, col, w, true)
			draw_line(c + Vector2(-u * 0.14, u * 0.32), c + Vector2(u * 0.14, u * 0.32), col, w, true)
			draw_line(c + Vector2(-u * 0.1, u * 0.5), c + Vector2(u * 0.1, u * 0.5), col, w, true)
			draw_line(c + Vector2(-u * 0.14, u * 0.12), c + Vector2(0, -u * 0.12), col, w * 0.7, true)
			draw_line(c + Vector2(u * 0.14, u * 0.12), c + Vector2(0, -u * 0.12), col, w * 0.7, true)
		"pause":
			draw_rect(Rect2(c + Vector2(-u * 0.3, -u * 0.34), Vector2(u * 0.22, u * 0.68)), col, true)
			draw_rect(Rect2(c + Vector2(u * 0.08, -u * 0.34), Vector2(u * 0.22, u * 0.68)), col, true)
		"power":
			draw_arc(c + Vector2(0, u * 0.04), u * 0.34, -PI * 0.3, -PI * 0.7 + TAU, 32, col, w, true)
			draw_line(c + Vector2(0, -u * 0.46), c + Vector2(0, -u * 0.04), col, w * 1.1, true)
		"globe":
			var gc := c + (Vector2(-u * 0.9, 0) if caption != "" else Vector2.ZERO)
			draw_arc(gc, u * 0.3, 0, TAU, 32, col, w * 0.8, true)
			draw_arc(gc, u * 0.3, -PI / 2, PI / 2, 12, col, w * 0.6, true)
			draw_line(gc + Vector2(-u * 0.3, 0), gc + Vector2(u * 0.3, 0), col, w * 0.6, true)
			draw_arc(gc + Vector2(-u * 0.25, 0), u * 0.35, -0.9, 0.9, 12, col, w * 0.6, true)
			if caption != "":
				draw_string(get_theme_font("font", "Button"), c + Vector2(-u * 0.38, u * 0.2), caption, HORIZONTAL_ALIGNMENT_LEFT, u * 2.0, 60, col)
		"note":
			draw_circle(c + Vector2(-u * 0.14, u * 0.3), u * 0.17, col)
			draw_line(c + Vector2(u * 0.02, u * 0.3), c + Vector2(u * 0.02, -u * 0.4), col, w, true)
			draw_line(c + Vector2(u * 0.02, -u * 0.4), c + Vector2(u * 0.3, -u * 0.25), col, w, true)
		"speaker":
			draw_colored_polygon(PackedVector2Array([c + Vector2(-u * 0.36, -u * 0.14), c + Vector2(-u * 0.14, -u * 0.14), c + Vector2(u * 0.08, -u * 0.34), c + Vector2(u * 0.08, u * 0.34), c + Vector2(-u * 0.14, u * 0.14), c + Vector2(-u * 0.36, u * 0.14)]), col)
			draw_arc(c + Vector2(u * 0.08, 0), u * 0.22, -0.8, 0.8, 10, col, w * 0.8, true)
			draw_arc(c + Vector2(u * 0.08, 0), u * 0.4, -0.8, 0.8, 10, col, w * 0.8, true)
		"play":
			draw_colored_polygon(PackedVector2Array([c + Vector2(-u * 0.22, -u * 0.38), c + Vector2(u * 0.4, 0), c + Vector2(-u * 0.22, u * 0.38)]), col)
		"next":
			draw_colored_polygon(PackedVector2Array([c + Vector2(-u * 0.3, -u * 0.38), c + Vector2(u * 0.28, 0), c + Vector2(-u * 0.3, u * 0.38)]), col)
			draw_line(c + Vector2(u * 0.42, -u * 0.36), c + Vector2(u * 0.42, u * 0.36), col, w * 1.2, true)
		"gear":
			draw_arc(c, u * 0.3, 0, TAU, 32, col, w, true)
			for k in 8:
				var d := Vector2.from_angle(k * TAU / 8.0)
				draw_line(c + d * u * 0.36, c + d * u * 0.5, col, w * 1.3, true)
			draw_circle(c, u * 0.1, col)
		"levels":
			for gy in 3:
				for gx in 3:
					draw_rect(Rect2(c + Vector2((gx - 1.5) * u * 0.34 + u * 0.03, (gy - 1.5) * u * 0.34 + u * 0.03), Vector2.ONE * u * 0.26), col, true)
		"back":
			draw_polyline(PackedVector2Array([c + Vector2(u * 0.12, -u * 0.4), c + Vector2(-u * 0.28, 0), c + Vector2(u * 0.12, u * 0.4)]), col, w * 1.1, true)
		"vibrate":
			draw_rect(Rect2(c + Vector2(-u * 0.16, -u * 0.38), Vector2(u * 0.32, u * 0.76)), col, false, w * 0.8)
			draw_arc(c, u * 0.5, -0.5, 0.5, 12, col, w * 0.7, true)
			draw_arc(c, u * 0.5, PI - 0.5, PI + 0.5, 12, col, w * 0.7, true)
			if toggle_mode and not button_pressed:
				draw_line(c + Vector2(-u * 0.5, u * 0.5), c + Vector2(u * 0.5, -u * 0.5), Color("FF4D6D"), w * 1.2, true)
		"home":
			var roof := PackedVector2Array([c + Vector2(-u * 0.5, -u * 0.05), c + Vector2(0, -u * 0.5), c + Vector2(u * 0.5, -u * 0.05)])
			draw_polyline(roof, col, w, true)
			draw_polyline(PackedVector2Array([c + Vector2(-u * 0.34, 0), c + Vector2(-u * 0.34, u * 0.45), c + Vector2(u * 0.34, u * 0.45), c + Vector2(u * 0.34, 0)]), col, w, true)
	if badge >= 0:
		var p := Vector2(size.x - 30, size.y - 30)
		draw_circle(p, 26, Color("0E1226"))
		draw_arc(p, 26, 0, TAU, 24, col, 3.0, true)
		var f := get_theme_font("font", "Button")
		draw_string(f, Vector2(p.x - 20, p.y + 12), str(badge), HORIZONTAL_ALIGNMENT_CENTER, 40, 34, Color.WHITE)


func _arrow_arc(c: Vector2, r: float, a0: float, a1: float, col: Color, w: float, at_start: bool) -> void:
	draw_arc(c, r, a0, a1, 40, col, w, true)
	var a := a0 if at_start else a1
	var tip := c + Vector2.from_angle(a) * r
	var tangent := Vector2(sin(a), -cos(a)) * (1.0 if at_start else -1.0)
	var n := tangent.orthogonal()
	var head := w * 2.2
	draw_colored_polygon(PackedVector2Array([tip + tangent * head, tip + n * head * 0.9, tip - n * head * 0.9]), col)
