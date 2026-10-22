extends Control
## First screen of every game: the game's own logo and name on the theme backdrop, then the main menu.
## The engine's boot splash is disabled in project.godot (no Godot logo); a tap skips this screen.
## Put the game's logo at res://assets/art/logo.png; without it the app icon is used.

const LOGO_PATH := "res://assets/art/logo.png"

@onready var _logo: TextureRect = %Logo
@onready var _title: Label = %Title

var _done := false


func _ready() -> void:
	_title.text = ProjectSettings.get_setting("application/config/name")
	var path: String = LOGO_PATH if ResourceLoader.exists(LOGO_PATH) else ProjectSettings.get_setting("application/config/icon")
	_logo.texture = load(path)
	var fast := false
	for arg in OS.get_cmdline_user_args():
		fast = fast or arg.begins_with("--playtest=")   # playtests must not wait for branding
	var fade := 0.05 if fast else 0.45
	var hold := 0.25 if fast else 0.9
	await get_tree().process_frame
	for c: Control in [_logo, _title]:
		c.pivot_offset = c.size / 2.0
		c.modulate.a = 0.0
		c.scale = Vector2.ONE * 0.92
	var t := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for c: Control in [_logo, _title]:
		t.tween_property(c, "modulate:a", 1.0, fade)
		t.tween_property(c, "scale", Vector2.ONE, fade)
	await get_tree().create_timer(fade + hold).timeout
	_finish(0.15 if fast else 0.3)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_finish(0.15)


func _finish(duration: float) -> void:
	if _done:
		return
	_done = true
	SceneTransition.change_scene(SceneTransition.MAIN_MENU_SCENE, duration)
