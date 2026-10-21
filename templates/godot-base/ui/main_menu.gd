extends Control

const SETTINGS_PANEL := preload("res://ui/settings_panel.tscn")

@onready var _title: Label = %Title
@onready var _play: Button = %PlayButton
@onready var _settings: Button = %SettingsButton
@onready var _quit: Button = %QuitButton


func _ready() -> void:
	_title.text = ProjectSettings.get_setting("application/config/name")
	_quit.visible = not (OS.has_feature("mobile") or OS.has_feature("web"))
	_play.pressed.connect(func() -> void: SceneTransition.change_scene(SceneTransition.GAME_SCENE))
	_settings.pressed.connect(func() -> void: add_child(SETTINGS_PANEL.instantiate()))
	_quit.pressed.connect(func() -> void: get_tree().quit())
	AudioManager.play_music("menu")
	_animate_in()


func _animate_in() -> void:
	await get_tree().process_frame
	var delay := 0.0
	for c: Control in [_title, _play, _settings, _quit]:
		if not c.visible:
			continue
		c.pivot_offset = c.size / 2.0
		c.modulate.a = 0.0
		c.scale = Vector2.ONE * 0.9
		var t := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(c, "modulate:a", 1.0, 0.3).set_delay(delay)
		t.tween_property(c, "scale", Vector2.ONE, 0.35).set_delay(delay)
		delay += 0.08
