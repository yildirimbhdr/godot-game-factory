extends Control
## Placeholder game: tap to score, reaching WIN_SCORE ends the run.
## Replace this scene's content with the real game; keep the Hud and the PauseManager call.

const GAME_OVER := preload("res://ui/game_over.tscn")
const WIN_SCORE := 5

var score := 0
var _over := false

@onready var _hud: Control = %Hud


func _ready() -> void:
	PauseManager.set_gameplay_active(true)
	AudioManager.play_music("gameplay")
	_hud.set_score(0)


func _unhandled_input(event: InputEvent) -> void:
	if _over or get_tree().paused:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		score += 1
		_hud.set_score(score)
		AudioManager.play_sfx("score", 0.05)
		Haptics.tap()
		if score >= WIN_SCORE:
			_end()


func _end() -> void:
	_over = true
	var overlay := GAME_OVER.instantiate()
	add_child(overlay)
	overlay.show_result(score)
