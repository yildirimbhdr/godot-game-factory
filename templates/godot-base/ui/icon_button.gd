class_name IconButton
extends UIButton
## Square touch button that shows a glyph instead of a word. Set `glyph`; optional `group_name` makes
## playtests able to tap it (`tap_group`). Toggle buttons dim their glyph while off.

@export var glyph: Texture2D
## Toggle buttons show this while off (e.g. a muted speaker); without it the glyph just dims.
@export var glyph_off: Texture2D
@export var group_name := ""
@export var glyph_size := 120
@export var button_size := 190.0


func _ready() -> void:
	super._ready()
	text = ""
	icon = glyph
	expand_icon = true
	icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	add_theme_constant_override("icon_max_width", glyph_size)
	custom_minimum_size = Vector2(button_size, button_size)
	if group_name != "":
		add_to_group(group_name)
	if toggle_mode:
		toggled.connect(func(_on: bool) -> void: _refresh())
		_refresh()


func _refresh() -> void:
	if glyph_off != null:
		icon = glyph if button_pressed else glyph_off
		modulate = Color.WHITE
	else:
		modulate = Color.WHITE if button_pressed else Color(1, 1, 1, 0.55)
