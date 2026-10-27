class_name StarRow
## Sprite version of StarRow (replaces ui/star_row.gd). It needs assets/art/star_on.png and star_off.png: make your own (a Gemini crystal star worked well).
extends Control
## Three reward stars (Gemini-made crystal star sprite). `show_stars(n)` pops the earned ones in one by one with a bounce,
## a ring of turning light rays, a sparkle burst and a rising pitch. `make(n, true)` is the small static version for level cells.

const STAR_ON := preload("res://assets/art/star_on.png")
const STAR_OFF := preload("res://assets/art/star_off.png")
const R := 100.0
const GOLD := Color("FFD166")

var earned := 0
var _scale: Array[float] = [0.0, 0.0, 0.0]
var _rays: Array[float] = [0.0, 0.0, 0.0]
var _spin := 0.0
var _small := false
var _spark: GradientTexture2D


static func make(count: int, small := false) -> StarRow:
	var row := StarRow.new()
	row._small = small
	row.earned = count
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.custom_minimum_size = Vector2(96, 32) if small else Vector2(3.0 * R * 2.1, R * 2.2)
	var start := 1.0 if small else 0.0
	row._scale.assign([start, start, start])
	return row


func _ready() -> void:
	_spark = GradientTexture2D.new()
	_spark.fill = GradientTexture2D.FILL_RADIAL
	_spark.fill_from = Vector2(0.5, 0.5)
	_spark.fill_to = Vector2(1.0, 0.5)
	_spark.width = 32
	_spark.height = 32
	_spark.gradient = Gradient.new()
	_spark.gradient.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	set_process(not _small)


func _process(delta: float) -> void:
	_spin += delta * 0.6
	if earned > 0:
		queue_redraw()


func show_stars(count: int, fx := 1.0) -> void:
	earned = count
	for i in 3:
		if fx <= 0.0:
			_scale[i] = 1.0
			continue
		var delay := 0.3 * fx * i
		var t := create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		t.tween_method(_set_scale.bind(i), 0.0, 1.0, 0.75 * fx).set_delay(delay)
		if i < count:
			get_tree().create_timer(delay).timeout.connect(_celebrate.bind(i))
	queue_redraw()


func _celebrate(i: int) -> void:
	AudioManager.play_sfx("star", 0.0, 1.0 + 0.22 * i)
	Haptics.tap()
	var ray := create_tween()
	ray.tween_method(_set_rays.bind(i), 0.0, 1.0, 0.25)
	ray.tween_method(_set_rays.bind(i), 1.0, 0.35, 0.9)
	var p := CPUParticles2D.new()
	p.texture = _spark
	p.position = _center(i)
	p.amount = 18
	p.one_shot = true
	p.explosiveness = 1.0
	p.lifetime = 0.8
	p.spread = 180.0
	p.initial_velocity_min = 220.0
	p.initial_velocity_max = 480.0
	p.gravity = Vector2.ZERO
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.2
	p.color = GOLD
	add_child(p)
	p.emitting = true
	get_tree().create_timer(1.2).timeout.connect(p.queue_free)


func _center(i: int) -> Vector2:
	return Vector2(size.x / 3.0 * (i + 0.5), size.y / 2.0)


func _set_scale(v: float, i: int) -> void:
	_scale[i] = v
	queue_redraw()


func _set_rays(v: float, i: int) -> void:
	_rays[i] = v
	queue_redraw()


func _draw() -> void:
	var r := 15.0 if _small else R
	for i in 3:
		var c := _center(i)
		var on := i < earned
		var sc := _scale[i]
		if on and not _small and _rays[i] > 0.0:
			for k in 10:   # turning light rays behind the star
				var a := _spin + k * TAU / 10.0
				var spread := 0.11
				draw_colored_polygon(PackedVector2Array([c, c + Vector2.from_angle(a - spread) * r * 2.1, c + Vector2.from_angle(a + spread) * r * 2.1]),
					Color(GOLD, 0.22 * _rays[i]))
			draw_circle(c, r * 1.25, Color(GOLD, 0.14 * _rays[i]))
		var px := r * 2.0 * sc
		draw_texture_rect(STAR_ON if on else STAR_OFF, Rect2(c - Vector2.ONE * px / 2.0, Vector2.ONE * px), false)
