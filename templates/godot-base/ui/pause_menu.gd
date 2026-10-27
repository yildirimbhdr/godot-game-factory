extends Control

const SETTINGS_PANEL := preload("res://ui/settings_panel.tscn")

@onready var _panel: Control = %Panel


func _ready() -> void:
	%ResumeButton.pressed.connect(PauseManager.resume_game)
	%RestartButton.pressed.connect(_restart)
	%SettingsButton.pressed.connect(func() -> void: add_child(SETTINGS_PANEL.instantiate()))
	%MenuButton.pressed.connect(_to_menu)
	_pop_in()


func _pop_in() -> void:
	await get_tree().process_frame
	_panel.pivot_offset = _panel.size / 2.0
	_panel.scale = Vector2.ONE * 0.85
	_panel.modulate.a = 0.0
	var t := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(_panel, "scale", Vector2.ONE, 0.25)
	t.tween_property(_panel, "modulate:a", 1.0, 0.15)


func _restart() -> void:
	PauseManager.resume_game()
	SceneTransition.reload()


func _to_menu() -> void:
	PauseManager.resume_game()
	SceneTransition.change_scene(SceneTransition.MAIN_MENU_SCENE)
