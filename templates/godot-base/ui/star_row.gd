class_name StarRow
extends Control
## Three stars drawn in code. `show_stars(n)` pops the earned ones in one by one with a rising pitch.

const GOLD := Color("FFD166")
const EMPTY := Color("39426F")
const R := 78.0

var earned := 0
var _scale: Array[float] = [0.0, 0.0, 0.0]
var _small := false


## `small` draws the compact version used under level numbers (no animation).
static func make(count: int, small := false) -> StarRow:
	var row := StarRow.new()
	row._small = small
	row.earned = count
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.custom_minimum_size = Vector2(90, 30) if small else Vector2(3.0 * R * 2.2, R * 2.2)
	var start := 1.0 if small else 0.0
	row._scale.assign([start, start, start])
	return row


func show_stars(count: int, fx := 1.0) -> void:
	earned = count
	for i in 3:
		if fx <= 0.0:
			_scale[i] = 1.0
			continue
		var t := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_method(_set_scale.bind(i), 0.0, 1.0, 0.4 * fx).set_delay(0.25 * fx * i)
		if i < count:
			get_tree().create_timer(0.25 * fx * i).timeout.connect(func() -> void:
				AudioManager.play_sfx("star", 0.0, 1.0 + 0.22 * i)
				Haptics.tap())
	queue_redraw()


func _set_scale(v: float, i: int) -> void:
	_scale[i] = v
	queue_redraw()


func _draw() -> void:
	var r := 13.0 if _small else R
	var step := size.x / 3.0
	for i in 3:
		var c := Vector2(step * (i + 0.5), size.y / 2.0)
		var on := i < earned
		var pts := PackedVector2Array()
		for k in 10:
			var rad := r * _scale[i] * (1.0 if k % 2 == 0 else 0.46)
			pts.append(c + Vector2.from_angle(-PI / 2.0 + k * PI / 5.0) * rad)
		draw_colored_polygon(pts, GOLD if on else EMPTY)
		if on and not _small:
			pts.append(pts[0])
			draw_polyline(pts, Color(1, 1, 1, 0.55), 4.0, true)
