extends Control
## Result overlay with icon buttons. Instance, add to the game scene, then call show_result().
## `stars` (0-3) shows the rating row, -1 hides it.

const STAR := preload("res://assets/art/icons/star.png")
const STAR_EMPTY := preload("res://assets/art/icons/star_empty.png")

## Where the menu button leads.
var menu_scene := SceneTransition.MAIN_MENU_SCENE
var score_label := "Score"

@onready var _panel: Control = %Panel


func _ready() -> void:
	%RetryButton.pressed.connect(SceneTransition.reload)
	%MenuButton.pressed.connect(func() -> void: SceneTransition.change_scene(menu_scene))


## `title` replaces "Game Over"; a valid `next` callable shows the big Next button that calls it.
func show_result(score: int, title := "Game Over", next := Callable(), stars := -1) -> void:
	%Title.text = title
	if next.is_valid():
		%NextButton.visible = true
		%NextButton.pressed.connect(next)
	PauseManager.set_gameplay_active(false)
	var best: int = Settings.get_value("best_score")
	if score > best:
		Settings.set_value("best_score", score)
	%ScoreLabel.text = "%s %d" % [score_label, score]
	%BestLabel.visible = false
	%Stars.visible = stars >= 0
	if stars >= 0:
		for i in 3:
			var star := TextureRect.new()
			star.texture = STAR if i < stars else STAR_EMPTY
			star.custom_minimum_size = Vector2(150, 150)
			star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			star.pivot_offset = Vector2(75, 75)
			star.scale = Vector2.ZERO
			%Stars.add_child(star)
	if stars < 0:
		AudioManager.play_sfx("game_over")
	Haptics.heavy()
	await get_tree().process_frame
	_panel.pivot_offset = _panel.size / 2.0
	_panel.scale = Vector2.ONE * 0.8
	_panel.modulate.a = 0.0
	var t := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(_panel, "scale", Vector2.ONE, 0.35)
	t.tween_property(_panel, "modulate:a", 1.0, 0.2)
	if stars >= 0:
		await get_tree().create_timer(0.45).timeout
		var kids := %Stars.get_children()
		for i in kids.size():
			var s: Control = kids[i]
			var pop := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			pop.tween_property(s, "scale", Vector2.ONE, 0.35)
			if i < stars:
				AudioManager.play_sfx("star", 0.0, 1.0 + i * 0.25)
				Haptics.tap()
			await get_tree().create_timer(0.28).timeout
