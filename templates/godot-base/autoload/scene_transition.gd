extends CanvasLayer
## Fade-to-black scene changes. Always use this instead of get_tree().change_scene_to_file().

const MAIN_MENU_SCENE := "res://ui/main_menu.tscn"
const GAME_SCENE := "res://game/game.tscn"

var _rect: ColorRect
var _busy := false


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = ColorRect.new()
	_rect.color = Color.BLACK
	_rect.modulate.a = 0.0
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_rect)


func change_scene(path: String, duration := 0.25) -> void:
	if _busy:
		return
	_busy = true
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var out := create_tween()
	out.tween_property(_rect, "modulate:a", 1.0, duration)
	await out.finished
	PauseManager.set_gameplay_active(false)
	get_tree().paused = false
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	var back := create_tween()
	back.tween_property(_rect, "modulate:a", 0.0, duration)
	await back.finished
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false


func reload(duration := 0.25) -> void:
	change_scene(get_tree().current_scene.scene_file_path, duration)
