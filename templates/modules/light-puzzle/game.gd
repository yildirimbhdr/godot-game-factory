class_name Game
extends Control
## Prism Path level scene: board, HUD, moves and stars, undo, restart, hint, win handling and saved progress.

const GAME_OVER := preload("res://ui/game_over.tscn")
const HINTS_PER_LEVEL := 3

static var level_index := 0
## Playtest helper: >0 solves this level and the next ones through the normal win screen and Next button.
static var autoplay_left := 0

var moves := 0
var fx := 1.0
var hints_left := HINTS_PER_LEVEL

var _level: Dictionary
var _gfx: GameFx
var _improved := false
var _lit_count := 0
var _last_lit_msec := 0

@onready var _hud: Control = %Hud
@onready var _board: Board = %Board
@onready var _status: StatusBar = %StatusBar
@onready var _undo: GlyphButton = %UndoButton
@onready var _restart: GlyphButton = %RestartButton
@onready var _hint: GlyphButton = %HintButton


func _ready() -> void:
	add_to_group("game")
	PauseManager.set_gameplay_active(true)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--playtest="):
			fx = 0.0   # rules are tested without animation time (lesson 0027); capture runs call set_fx
	var from_env := OS.get_environment("PRISM_LEVEL")   # review helper: PRISM_LEVEL=42 starts at level 42
	if from_env.is_valid_int():
		level_index = clampi(int(from_env) - 1, 0, Levels.DATA.size() - 1)
	AudioManager.play_music("gameplay")
	_level = Levels.DATA[level_index]
	_board.fx = fx
	_board.flipped.connect(_on_flipped)
	_board.undone.connect(_on_undone)
	_board.crystal_lit.connect(_on_crystal_lit)
	_board.solved.connect(_on_solved)
	%Background.dim = 0.4
	%Background.texture = load("res://assets/art/bg_world%d.jpg" % (Levels.world_of(level_index) + 1))
	var world := Levels.world_of(level_index)
	_board.accent = Levels.WORLD_COLORS[world]
	_status.setup(tr(Levels.WORLD_NAMES[world]), Levels.WORLD_COLORS[world], int(_level.par))
	_setup_fx()
	_board.setup(_level)
	_undo.pressed.connect(_on_undo)
	_restart.pressed.connect(SceneTransition.reload)
	_hint.pressed.connect(_on_hint)
	_hud.set_title(tr("Level %d") % (level_index + 1))
	_place_board.call_deferred()
	_hint.badge = hints_left
	_refresh()
	if autoplay_left > 0:
		_autoplay()
	if level_index % Levels.LEVELS_PER_WORLD == 0:
		HowTo.show_once(self, "world%d" % world, Levels.WORLD_HINTS[world])


## Capture runs re-enable effects as their first step (see playtest/*.json).
func set_fx(value: float) -> void:
	fx = value
	_board.fx = value


## Playtest hooks.
func tap_mirror(index: int) -> void:
	_board.flip(index)


func tap_hint() -> void:
	_on_hint()


func tap_undo() -> void:
	_on_undo()


## Playtest helper (see autoplay_left): plays `levels` levels from the current one using the real UI flow.
func start_autoplay(levels: int) -> void:
	autoplay_left = levels
	_autoplay()


func _autoplay() -> void:
	await get_tree().create_timer(0.25).timeout
	autosolve()


## Flips every mirror to the solver's best state, one by one (used to clear a level in playtests).
func autosolve() -> void:
	var sol := Optics.solve(_level, _board.kinds)
	for i in (sol.kinds as Array).size():
		if int(sol.kinds[i]) != int(_board.kinds[i]):
			_board.flip(i)


func _refresh() -> void:
	_status.set_moves(moves)
	_undo.disabled = not _board.can_undo()
	_undo.queue_redraw()


## The board starts below the status pill, whatever the notch pushed down.
func _place_board() -> void:
	await get_tree().process_frame
	_board.offset_top = _status.global_position.y + _status.size.y + 24.0
	_board.queue_redraw()


func _setup_fx() -> void:
	var fx_root := Node2D.new()
	add_child(fx_root)
	var camera := Camera2D.new()
	camera.position = get_viewport_rect().size / 2.0
	add_child(camera)
	get_viewport().size_changed.connect(func() -> void: camera.position = get_viewport_rect().size / 2.0)
	_gfx = GameFx.new()
	add_child(_gfx)
	_gfx.setup(fx_root, camera, {"red": Color("FF4D6D"), "yellow": Color("FFD166"), "green": Color("3DDC97"), "cyan": Color("5DE0E6"), "blue": Color("4D9BFF"), "magenta": Color("D65DB1")}, Color("B8C4FF"))


func _on_flipped(index: int) -> void:
	if fx > 0.0:
		_gfx.burst(_board.mirror_point(index), Color("B8C4FF"), 9, 0.5, 0.0, 0.45)
	moves += 1
	AudioManager.play_sfx("mirror_flip", 0.06)
	Haptics.tap()
	_refresh()


func _on_undone(_index: int) -> void:
	moves = maxi(moves - 1, 0)
	AudioManager.play_sfx("undo")
	_refresh()


func _on_crystal_lit(open_count: int, index: int) -> void:
	AudioManager.play_sfx("crystal", 0.0, 1.0 + 0.14 * float(open_count - 1))
	Haptics.tap()
	if fx <= 0.0:
		return
	var color: Color = Board.COLORS[int(_level.crystals[index].color)]
	var at := _board.crystal_point(index)
	_gfx.burst(at, color, 26, 1.0, 120.0, 0.9)
	var now := Time.get_ticks_msec()
	_lit_count = _lit_count + 1 if now - _last_lit_msec < 150 else 1
	_last_lit_msec = now
	if _lit_count >= 2:
		var words := {2: "Double!", 3: "Triple!"}
		var praise: String = words.get(_lit_count, "Wow!")
		_gfx.popup(tr(praise), at + Vector2(0, -90), Color("FFD166"), 72)


func _on_undo() -> void:
	if not _board.undo():
		AudioManager.play_sfx("locked")


func _on_hint() -> void:
	if hints_left <= 0 or Optics.is_solved(_board.result.open):
		AudioManager.play_sfx("locked")
		return
	var sol := Optics.solve(_level, _board.kinds)
	for i in (sol.kinds as Array).size():
		if int(sol.kinds[i]) != int(_board.kinds[i]):
			hints_left -= 1
			_hint.badge = hints_left
			_board.show_hint(i)
			AudioManager.play_sfx("hint")
			return


func _on_solved() -> void:
	var stars := Levels.stars_for(moves, int(_level.par))
	var streak := _save_progress(stars)
	AudioManager.play_sfx("win")
	Haptics.heavy()
	_celebrate(stars, streak)
	await get_tree().create_timer(1.0 * maxf(fx, 0.05)).timeout
	var overlay := GAME_OVER.instantiate()
	overlay.menu_scene = SceneTransition.LEVEL_SELECT_SCENE
	overlay.menu_text = tr("Levels")
	overlay.score_label = "Moves"
	add_child(overlay)
	var has_next := level_index + 1 < Levels.DATA.size()
	var next := Callable()
	if has_next:
		next = func() -> void:
			level_index += 1
			SceneTransition.reload()
	var info := tr("Par %d") % int(_level.par)
	if int(Settings.get_value("streak", 0)) >= 2:
		info += "   " + tr("Streak x%d") % int(Settings.get_value("streak", 0))
	var world := Levels.world_of(level_index)
	var extra := {"accent": Levels.WORLD_COLORS[world], "world_name": tr(Levels.WORLD_NAMES[world]), "world_first": world * Levels.LEVELS_PER_WORLD,
		"level_index": level_index, "level_in_world": level_index % Levels.LEVELS_PER_WORLD + 1, "improved": _improved}
	overlay.show_result(moves, "Level Clear!", next, stars, info, extra)
	if autoplay_left > 0:
		autoplay_left -= 1
		if autoplay_left > 0 and has_next:
			await get_tree().create_timer(0.3).timeout
			overlay.get_node("%NextButton").pressed.emit()


func _celebrate(stars: int, _streak: int) -> void:
	if fx <= 0.0:
		return
	var center := _board.board_center()
	_gfx.flash(Color("B8C4FF"), 0.3, 0.55)
	_gfx.shake(10.0)
	_gfx.confetti(Vector2(540, -20), 110 if stars == 3 else 60, true)
	if stars == 3:
		_gfx.confetti(center, 40)
	var word: String = ["Nice!", "Great!", "Perfect!"][stars - 1]
	_gfx.popup(tr(word), center, Color("FFD166"), 110)
	if level_index % Levels.LEVELS_PER_WORLD == Levels.LEVELS_PER_WORLD - 1:
		get_tree().create_timer(0.7).timeout.connect(func() -> void:
			_gfx.confetti(Vector2(540, -20), 140, true)
			_gfx.popup(tr("World complete!"), center + Vector2(0, -170), Color("3DDC97"), 96))


## Returns the new streak: consecutive levels cleared at par (three stars).
func _save_progress(stars: int) -> int:
	var saved: Dictionary = (Settings.get_value("stars", {}) as Dictionary).duplicate()
	var key := str(level_index)
	_improved = stars > int(saved.get(key, 0)) and int(saved.get(key, 0)) > 0
	saved[key] = maxi(int(saved.get(key, 0)), stars)
	Settings.set_value("stars", saved, false)
	if level_index + 2 > int(Settings.get_value("level_unlocked", 1)):
		Settings.set_value("level_unlocked", mini(level_index + 2, Levels.DATA.size()), false)
		Settings.set_value("just_unlocked", level_index + 1, false)
	var streak: int = int(Settings.get_value("streak", 0)) + 1 if stars == 3 else 0
	Settings.set_value("streak", streak, false)
	Settings.flush()
	return streak
