class_name WorldProgress
extends Control
## Ten pips for the levels of one world: cleared (world colour), the one just played (pulses), still to do (dim).

var accent := Color("B8C4FF")
var first_level := 0
var current := 0
var _pulse := 0.0


func setup(world_first_level: int, current_level: int, color: Color, animate := true) -> WorldProgress:
	first_level = world_first_level
	current = current_level
	accent = color
	custom_minimum_size = Vector2(620, 44)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if animate:
		var t := create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		t.tween_method(_set_pulse, 0.0, 1.0, 0.7)
		t.tween_method(_set_pulse, 1.0, 0.0, 0.7)
	return self


func _set_pulse(v: float) -> void:
	_pulse = v
	queue_redraw()


func _draw() -> void:
	var stars: Dictionary = Settings.get_value("stars", {})
	var n := Levels.LEVELS_PER_WORLD
	var step := size.x / float(n)
	for k in n:
		var i := first_level + k
		var c := Vector2(step * (k + 0.5), size.y / 2.0)
		var done := int(stars.get(str(i), 0)) > 0
		if i == current:
			draw_circle(c, 17.0 + 6.0 * _pulse, Color(accent, 0.25 + 0.25 * _pulse))
			draw_circle(c, 14.0, accent.lightened(0.35))
		elif done:
			draw_circle(c, 12.0, accent)
		else:
			draw_arc(c, 11.0, 0, TAU, 20, Color("39426F"), 3.0, true)
