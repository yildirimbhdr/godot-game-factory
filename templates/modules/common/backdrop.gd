extends Control
## Soft pastel background: vertical gradient, big blurry blobs and faint game icons drifting slowly.

const TOP := Color("FFF4E8")
const BOTTOM := Color("E9DDFB")
const ICONS := [
	"res://assets/art/icons/gear.png", "res://assets/art/icons/star.png", "res://assets/art/icons/home.png",
	"res://assets/art/screws/screw_mint.png", "res://assets/art/screws/screw_sky.png", "res://assets/art/screws/screw_peach.png",
	"res://assets/art/screws/screw_butter.png", "res://assets/art/screws/screw_lavender.png", "res://assets/art/screws/screw_coral.png",
]

var top := TOP
var bottom := BOTTOM
var blobs: Array = [Color("FFC8D8", 0.28), Color("BFE6FF", 0.30), Color("C9F2DD", 0.30)]
var _decor: Array[Sprite2D] = []
var _spin: Array[float] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	var view := get_viewport_rect().size
	var cols := 4
	var rows := 7
	for i in cols * rows:
		var cell := Vector2(i % cols, i / cols)
		var sprite := Sprite2D.new()
		sprite.texture = load(ICONS[rng.randi() % ICONS.size()])
		var size := rng.randf_range(0.5, 0.9)
		sprite.scale = Vector2.ONE * size
		sprite.rotation = rng.randf_range(-PI, PI)
		sprite.modulate = Color(1, 1, 1, rng.randf_range(0.10, 0.17))
		sprite.position = Vector2((cell.x + rng.randf_range(0.2, 0.8)) * view.x / cols, (cell.y + rng.randf_range(0.2, 0.8)) * view.y / rows)
		add_child(sprite)
		_decor.append(sprite)
		_spin.append(rng.randf_range(-0.12, 0.12))


func _process(delta: float) -> void:
	for i in _decor.size():
		_decor[i].rotation += _spin[i] * delta


func _draw() -> void:
	var w := size.x
	var h := size.y
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)]),
		PackedColorArray([top, top, bottom, bottom]))
	draw_circle(Vector2(w * 0.1, h * 0.12), w * 0.45, Color(blobs[0], 0.28))
	draw_circle(Vector2(w * 0.95, h * 0.45), w * 0.5, Color(blobs[1], 0.30))
	draw_circle(Vector2(w * 0.2, h * 0.9), w * 0.55, Color(blobs[2], 0.30))


## Re-colour for a world (see Levels.WORLDS): gradient ends and the three background blobs.
func set_palette(top_color: Color, bottom_color: Color, blob_colors: Array) -> void:
	top = top_color
	bottom = bottom_color
	blobs = blob_colors
	queue_redraw()
