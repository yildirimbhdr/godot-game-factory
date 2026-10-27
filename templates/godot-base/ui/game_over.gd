extends Control
## Instance, add to the game scene, then call show_result(score).

## Where the menu button leads and what it says (e.g. a level map instead of the main menu).
var menu_scene := SceneTransition.MAIN_MENU_SCENE
var menu_text := "Main Menu"
var score_label := "Score"

@onready var _panel: Control = %Panel


func _ready() -> void:
	%RetryButton.pressed.connect(SceneTransition.reload)
	%MenuButton.pressed.connect(func() -> void: SceneTransition.change_scene(menu_scene))


## `title` replaces "Game Over" (e.g. "Level Clear!"); a valid `next` callable shows a "Next" button that calls it.
func show_result(score: int, title := "Game Over", next := Callable(), stars := -1, best_text := "") -> void:
	%Title.text = title
	%MenuButton.text = menu_text
	%MenuButton.glyph = "levels" if menu_scene == SceneTransition.LEVEL_SELECT_SCENE else "home"
	if next.is_valid():
		%NextButton.visible = true
		%NextButton.pressed.connect(next)
	PauseManager.set_gameplay_active(false)
	var best: int = Settings.get_value("best_score")
	var is_new_best := score > best and stars < 0
	if is_new_best:
		best = score
		Settings.set_value("best_score", best)
	%ScoreLabel.text = "%s %d" % [tr(score_label), score]
	%RetryButton.text = "Retry" if not next.is_valid() else "Replay"
	%BestLabel.text = tr("New best!") if is_new_best else tr("Best %d") % best
	if best_text != "":
		%BestLabel.text = best_text
	var row: StarRow
	if stars >= 0:
		row = StarRow.make(stars)
		var column: VBoxContainer = $Center/Panel/Column
		column.add_child(row)
		column.move_child(row, %Title.get_index() + 1)
	else:
		AudioManager.play_sfx("game_over")
	Haptics.heavy()
	await get_tree().process_frame
	_panel.pivot_offset = _panel.size / 2.0
	_panel.scale = Vector2.ONE * 0.8
	_panel.modulate.a = 0.0
	var t := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(_panel, "scale", Vector2.ONE, 0.35)
	t.tween_property(_panel, "modulate:a", 1.0, 0.2)
	if row:
		await get_tree().create_timer(0.35).timeout
		row.show_stars(stars, 0.0 if _no_fx() else 1.0)


func _no_fx() -> bool:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--playtest="):
			return true
	return false
