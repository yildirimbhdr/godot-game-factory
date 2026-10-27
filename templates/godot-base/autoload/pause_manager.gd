extends Node
## Pause handling: on-screen button (via Hud), ESC/P on desktop, Android back button,
## and auto-pause when the app loses focus or goes to the background during play.

signal paused_changed(is_paused: bool)

const PAUSE_MENU := preload("res://ui/pause_menu.tscn")

## The game scene sets this true while a run is in progress.
var gameplay_active := false

var _layer: CanvasLayer
var _menu: Control
## Desktop window focus is unpredictable during automated playtests; they trigger
## backgrounding explicitly with the "app_background" step instead.
var _ignore_focus_loss := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().set_quit_on_go_back(false)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--playtest="):
			_ignore_focus_loss = true
	_layer = CanvasLayer.new()
	_layer.layer = 90
	add_child(_layer)
	_register_action()


func set_gameplay_active(active: bool) -> void:
	gameplay_active = active
	if not active and get_tree().paused:
		resume_game()


func is_paused() -> bool:
	return get_tree().paused


func toggle() -> void:
	if get_tree().paused:
		resume_game()
	else:
		pause_game()


func pause_game() -> void:
	if not gameplay_active or get_tree().paused:
		return
	get_tree().paused = true
	_menu = PAUSE_MENU.instantiate()
	_layer.add_child(_menu)
	paused_changed.emit(true)


func resume_game() -> void:
	if not get_tree().paused:
		return
	get_tree().paused = false
	if is_instance_valid(_menu):
		_menu.queue_free()
	_menu = null
	paused_changed.emit(false)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and gameplay_active:
		toggle()
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST:
			if gameplay_active:
				toggle()
			else:
				get_tree().quit()
		NOTIFICATION_APPLICATION_PAUSED:
			pause_game()
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			if not _ignore_focus_loss:
				pause_game()


func _register_action() -> void:
	if InputMap.has_action("pause"):
		return
	InputMap.add_action("pause")
	for key in [KEY_ESCAPE, KEY_P]:
		var e := InputEventKey.new()
		e.physical_keycode = key
		InputMap.action_add_event("pause", e)
