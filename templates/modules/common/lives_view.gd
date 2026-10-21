class_name LivesView
extends Node2D
## Row of hearts. `lose()` removes one and returns how many are left (0 = out of lives).
##   lives.setup(3, Vector2(540, 178)); if lives.lose() <= 0: game_over()
## Pair it with GameFx.heart_break(at) and GameFx.flash() for the mistake feedback.

const OUTLINE := Color("5B4B8A")

var max_lives := 3
var lives := 3
var spacing := 80.0
var scale_hearts := 1.6
var _pts := PackedVector2Array()


func setup(count: int, center: Vector2) -> LivesView:
	max_lives = count
	lives = count
	position = center
	z_index = 150
	for i in 40:
		var t := TAU * i / 40.0
		_pts.append(Vector2(16.0 * pow(sin(t), 3.0), -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))) * scale_hearts)
	queue_redraw()
	return self


func lose() -> int:
	lives = maxi(lives - 1, 0)
	queue_redraw()
	return lives


func reset() -> void:
	lives = max_lives
	queue_redraw()


func _draw() -> void:
	for i in max_lives:
		var xf := Transform2D(0.0, Vector2((i - (max_lives - 1) / 2.0) * spacing, 0.0))
		var alive := i < lives
		var poly := xf * _pts
		draw_colored_polygon(poly, Color("FF5E73") if alive else Color("D9D4E4"))
		var closed := poly.duplicate()
		closed.append(poly[0])
		draw_polyline(closed, OUTLINE, 5.0, true)
		if alive:
			draw_arc(xf * Vector2(-9, -10), 11.0, deg_to_rad(200), deg_to_rad(260), 8, Color(1, 1, 1, 0.8), 5.0, true)
