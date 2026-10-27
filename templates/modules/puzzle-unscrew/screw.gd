class_name Screw
extends Node2D
## A screw head drawn in the game's style (thick purple outline, glossy arc, cross).
## On a plate it is tappable while uncovered; in a jar or the tray it is just decoration.

const OUTLINE := Color("5B4B8A")
const R := 34.0

var color_name := ""
var color := Color.WHITE
var plate: Piece = null
var joint: PinJoint2D = null


func setup(color_key: String) -> Screw:
	color_name = color_key
	color = Levels.COLORS[color_key]
	return self


func _draw() -> void:
	draw_circle(Vector2(0, 4), R, Color(OUTLINE, 0.25))
	draw_circle(Vector2.ZERO, R, color)
	draw_circle(Vector2(0, R * 0.25), R * 0.8, color.darkened(0.08))
	draw_circle(Vector2(0, -R * 0.05), R * 0.8, color)
	draw_arc(Vector2.ZERO, R, 0.0, TAU, 48, OUTLINE, 7.0, true)
	draw_arc(Vector2.ZERO, R * 0.66, deg_to_rad(205), deg_to_rad(265), 12, Color(1, 1, 1, 0.8), 6.0, true)
	var cross := color.darkened(0.5)
	draw_line(Vector2(-R * 0.45, 0), Vector2(R * 0.45, 0), cross, 8.0, true)
	draw_line(Vector2(0, -R * 0.45), Vector2(0, R * 0.45), cross, 8.0, true)
