extends Control
## In-game overlay. Every game keeps this pause button reachable during play.

@onready var _score: Label = %ScoreLabel
@onready var _pause: Button = %PauseButton


func _ready() -> void:
	_pause.add_to_group("pause_button")  # playtests tap it with tap_group when the button shows an icon, not text
	_pause.pressed.connect(PauseManager.pause_game)


func set_score(value: int) -> void:
	_score.text = str(value)
	_score.pivot_offset = Vector2(0, _score.size.y / 2.0)
	_score.scale = Vector2.ONE * 1.25
	create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT) \
		.tween_property(_score, "scale", Vector2.ONE, 0.25)


## For games that show a level name or other text instead of a score.
func set_title(text: String) -> void:
	_score.text = text
