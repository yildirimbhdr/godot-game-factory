extends Control
## Level map: a winding path of screw-head stops, scrolled to the current level.

const SPACING := 270.0
const TOP_PAD := 380.0
const BOTTOM_PAD := 320.0
const WORLD_GAP := 130.0   # extra room before each world so its banner fits between two stops
const CARD_COLORS := ["mint", "sky", "peach", "butter", "lavender", "coral"]

@onready var _scroll: ScrollContainer = %Scroll
@onready var _content: Control = %Content
@onready var _title: Label = %Title
@onready var _home: Button = %HomeButton


func _ready() -> void:
	_home.pressed.connect(func() -> void: SceneTransition.change_scene(SceneTransition.MAIN_MENU_SCENE))
	PauseManager.set_gameplay_active(false)
	AudioManager.play_music("menu")
	_build()


func _build() -> void:
	var count := Levels.DATA.size()
	var unlocked: int = clampi(Settings.get_value("level_unlocked"), 1, count)
	var width := get_viewport_rect().size.x
	var stars: Dictionary = Settings.get_value("stars")
	var worlds := (count - 1) / Levels.LEVELS_PER_WORLD
	var height := TOP_PAD + BOTTOM_PAD + SPACING * (count - 1) + WORLD_GAP * worlds + 160.0
	_content.custom_minimum_size = Vector2(width, height)
	var points: Array[Vector2] = []
	for i in count:
		var y := height - BOTTOM_PAD - SPACING * i - WORLD_GAP * (i / Levels.LEVELS_PER_WORLD)
		var x := width / 2.0 + sin(i * 1.15) * width * 0.26
		points.append(Vector2(x, y))
	_content.draw.connect(func() -> void:
		for i in count - 1:
			_content.draw_dashed_line(points[i], points[i + 1], Color("5B4B8A", 0.35), 10.0, 22.0, true))
	for i in count:
		var node := LevelNode.new().setup(i, Levels.world_of(i)["node"],
			i + 1 > unlocked, i + 1 < unlocked, i + 1 == unlocked, int(stars.get(str(i), 0)))
		node.position = points[i] - node.size / 2.0
		node.chosen.connect(_play)
		_content.add_child(node)
		node.add_to_group("level_node")
		if i % Levels.LEVELS_PER_WORLD == 0:   # world banner above the first stop of each world
			var banner := Label.new()
			banner.text = "World %d  -  %s" % [i / Levels.LEVELS_PER_WORLD + 1, Levels.world_of(i)["name"]]
			banner.add_theme_font_size_override("font_size", 64)
			banner.custom_minimum_size = Vector2(width, 0)
			banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			banner.position = Vector2(0, points[i].y + (190.0 if i > 0 else 175.0))
			banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_content.add_child(banner)
		var tag := Label.new()
		tag.text = Levels.DATA[i]["name"]
		tag.add_theme_font_size_override("font_size", 40)
		tag.custom_minimum_size = Vector2(300, 0)
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag.position = points[i] + Vector2(-150, 128)
		tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_content.add_child(tag)
	_content.queue_redraw()
	await get_tree().process_frame
	await get_tree().process_frame
	_scroll.scroll_vertical = int(points[unlocked - 1].y - _scroll.size.y * 0.55)


func _play(index: int) -> void:
	Game.level_index = index
	SceneTransition.change_scene(SceneTransition.GAME_SCENE)
