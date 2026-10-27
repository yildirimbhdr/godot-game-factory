extends Control

const SETTINGS_PANEL := preload("res://ui/settings_panel.tscn")

@onready var _title: Label = %Title
@onready var _play: GlyphButton = %PlayButton
@onready var _settings: Button = %SettingsButton
@onready var _quit: Button = %QuitButton

var _animate_targets: Array[Control] = []
var _logo: Control


func _ready() -> void:
	_title.text = ProjectSettings.get_setting("application/config/name")
	if ResourceLoader.exists("res://assets/art/logo.png"):   # optional: a game logo above the title
		var logo := TextureRect.new()
		logo.texture = load("res://assets/art/logo.png")
		logo.custom_minimum_size = Vector2(560, 400)
		logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_title.get_parent().add_child(logo)
		_title.get_parent().move_child(logo, _title.get_index())
		_logo = logo
	_animate_targets.assign([_title, _settings, _play, _quit])
	if _logo:
		_animate_targets.insert(0, _logo)
	_quit.visible = not (OS.has_feature("mobile") or OS.has_feature("web"))
	_play.pressed.connect(func() -> void: SceneTransition.change_scene(SceneTransition.GAME_SCENE))
	_settings.pressed.connect(func() -> void: add_child(SETTINGS_PANEL.instantiate()))
	_quit.pressed.connect(func() -> void: get_tree().quit())
	AudioManager.play_music("menu")
	_style_play()
	_animate_in()


func _animate_in() -> void:
	await get_tree().process_frame
	var delay := 0.0
	for c: Control in _animate_targets:
		if not c.visible:
			continue
		c.pivot_offset = c.size / 2.0
		c.modulate.a = 0.0
		c.scale = Vector2.ONE * 0.9
		var t := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(c, "modulate:a", 1.0, 0.3).set_delay(delay)
		t.tween_property(c, "scale", Vector2.ONE, 0.35).set_delay(delay)
		delay += 0.08


## The play button is the one bright, glowing, softly pulsing thing on the screen.
func _style_play() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.42, 0.49, 1.0, 0.55)
	style.border_color = Color.WHITE
	style.set_border_width_all(4)
	style.set_corner_radius_all(150)
	style.shadow_color = Color(0.36, 0.88, 0.9, 0.45)
	style.shadow_size = 30
	for state in ["normal", "hover", "pressed"]:
		_play.add_theme_stylebox_override(state, style)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--playtest="):
			return
	var pulse := create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property(style, "shadow_size", 46, 0.9)
	pulse.tween_property(style, "shadow_size", 24, 0.9)
