extends Node
## Scripted touch playtest. Inert unless launched with: -- --playtest=<scenario.json>
## Run it through scripts/playtest.sh (Godot Movie Maker, fixed fps, deterministic).
##
## Scenario: JSON array of steps, "t" = seconds since start, coordinates in viewport (base) pixels.
##   {"t": 1.0, "do": "tap", "x": 540, "y": 960}
##   {"t": 1.5, "do": "tap_text", "text": "Play"}        taps the visible Button with that text
##   {"t": 2.0, "do": "mark", "name": "menu"}             logs the frame to keep as marks/<name>.png
##   {"t": 2.0, "do": "expect_text", "text": "Paused"}    FAIL if no visible Label/Button shows it
##   {"t": 2.0, "do": "expect_paused", "value": true}
##   {"t": 2.0, "do": "action", "name": "pause"}          presses an InputMap action
##   {"t": 2.0, "do": "tap_group", "group": "tappable", "index": 0}   taps the centre of the index-th node of a group
##        optional "where": {"color_name": "sky"} keeps only nodes whose property matches; negative index counts from the end
##   {"t": 2.0, "do": "call", "group": "game", "method": "_end", "args": [false]}   calls a method on the first node of a group
##   {"t": 2.0, "do": "expect_group_count", "group": "tappable", "min": 1, "max": 5}
##   {"t": 2.0, "do": "app_background"}                   simulates the app going to the background
##   {"t": 2.0, "do": "slide", "name": "MusicSlider", "value": 0.0}   sets a slider found by node name
##   {"t": 2.0, "do": "expect_bus_muted", "bus": "Music", "value": true}
##   {"t": 0.1, "do": "setting", "key": "level_unlocked", "value": 14}   seeds a Settings value (playtests are ephemeral; used to stage store screenshots)
## Failures are logged as "[playtest][FAIL] ..." and make playtest.sh exit non-zero.
##
## Animation is off during playtests so rules cannot depend on it, which also hides particles, labels and
## flashes from captured marks (lesson 0027). A game therefore exposes `set_fx(value)` on its "game" node, and
## capture runs (clips, store screenshots, juice review) turn effects back on as their first step:
##   {"t": 0.1, "do": "call", "group": "game", "method": "set_fx", "args": [1.0]}
## Keep correctness scenarios (effects off) and showcase scenarios (effects on) in separate files rather than
## making one serve both. Any helper that stages game state for a capture must advance the game itself, or an
## ordinary tick slips in between staged steps and breaks the sequence being staged.

var _steps: Array = []
var _elapsed := 0.0
var _shots_dir := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--playtest="):
			var f := FileAccess.open(arg.trim_prefix("--playtest="), FileAccess.READ)
			if f == null:
				push_error("[playtest][FAIL] cannot open scenario")
				return
			_steps = JSON.parse_string(f.get_as_text())
			print("[playtest] loaded ", _steps.size(), " steps")
		elif arg.begins_with("--shots="):
			_shots_dir = arg.trim_prefix("--shots=")
	set_process(not _steps.is_empty())


func _process(delta: float) -> void:
	_elapsed += delta
	while not _steps.is_empty() and _steps[0].t <= _elapsed:
		_run(_steps.pop_front())


func _run(s: Dictionary) -> void:
	match s["do"]:
		"tap":
			_tap(Vector2(s.x, s.y))
			print("[playtest] tap ", s.x, ",", s.y)
		"tap_text":
			var b := _find_button(get_tree().root, s.text)
			if b == null:
				_fail("no visible button with text '%s'" % s.text)
			else:
				_tap(b.get_global_rect().get_center())
				print("[playtest] tap_text '", s.text, "'")
		"mark":
			print("[playtest] mark ", s.get("name", ""), " frame=", Engine.get_process_frames())
			# The viewport is saved directly: Movie Maker frame numbers drift from process frames in heavy scenes.
			if _shots_dir != "":
				get_viewport().get_texture().get_image().save_png("%s/%s.png" % [_shots_dir, s.get("name", "mark")])
		"setting":
			Settings.set_value(s.key, s.value, false)
			print("[playtest] setting ", s.key)
		"expect_text":
			if not _text_visible(get_tree().root, s.text):
				_fail("expected visible text '%s'" % s.text)
		"expect_paused":
			if get_tree().paused != s.value:
				_fail("expected paused=%s" % s.value)
		"slide":
			var slider := _find_named(get_tree().root, s.name) as Range
			if slider == null:
				_fail("no slider named '%s'" % s.name)
			else:
				slider.value = s.value
				print("[playtest] slide ", s.name, " -> ", s.value)
		"expect_bus_muted":
			if AudioServer.is_bus_mute(AudioServer.get_bus_index(s.bus)) != s.value:
				_fail("expected bus %s muted=%s" % [s.bus, s.value])
		"tap_group":
			var nodes := get_tree().get_nodes_in_group(s.group).filter(func(n: Node) -> bool:
				for k in s.get("where", {}):
					if n.get(k) != s.where[k]:
						return false
				return true)
			var idx: int = s.get("index", 0)
			if idx < 0:
				idx += nodes.size()
			if idx >= nodes.size() or not (nodes[idx] is Node2D or nodes[idx] is Control):
				_fail("no node %d in group '%s' (have %d)" % [idx, s.group, nodes.size()])
			else:
				var n = nodes[idx]
				_tap(n.get_global_transform_with_canvas().origin if n is Node2D else n.get_global_rect().get_center())
				print("[playtest] tap_group ", s.group, " #", idx)
		"call":
			var target := get_tree().get_first_node_in_group(s.group)
			if target == null or not target.has_method(s.method):
				_fail("no node in group '%s' with method '%s'" % [s.group, s.method])
			else:
				target.callv(s.method, s.get("args", []))
				print("[playtest] call ", s.group, ".", s.method)
		"expect_group_count":
			var count := get_tree().get_nodes_in_group(s.group).size()
			if count < int(s.get("min", 0)) or count > int(s.get("max", 1 << 30)):
				_fail("group '%s' has %d nodes, expected %s..%s" % [s.group, count, s.get("min", 0), s.get("max", "inf")])
		"app_background":
			PauseManager.notification(NOTIFICATION_APPLICATION_PAUSED)
			print("[playtest] app_background")
		"action":
			Input.action_press(s.name)
			Input.action_release(s.name)
			print("[playtest] action ", s.name)
		_:
			_fail("unknown step '%s'" % s["do"])


func _fail(msg: String) -> void:
	push_error("[playtest][FAIL] " + msg)
	print("[playtest][FAIL] ", msg)


## Position is in viewport coordinates; injected events are expected in window pixels.
func _tap(viewport_pos: Vector2) -> void:
	var pos := get_viewport().get_final_transform() * viewport_pos
	for down in [true, false]:
		var e := InputEventScreenTouch.new()
		e.index = 0
		e.position = pos
		e.pressed = down
		Input.parse_input_event(e)


func _find_button(node: Node, text: String) -> Button:
	for i in range(node.get_child_count() - 1, -1, -1):
		var found := _find_button(node.get_child(i), text)
		if found:
			return found
	if node is Button and node.is_visible_in_tree() and not node.disabled and node.text == text:
		return node
	return null


func _find_named(node: Node, node_name: String) -> Node:
	if node.name == node_name:
		return node
	for c in node.get_children():
		var found := _find_named(c, node_name)
		if found:
			return found
	return null


func _text_visible(node: Node, text: String) -> bool:
	if (node is Label or node is Button) and node.is_visible_in_tree() and node.text.contains(text):
		return true
	for c in node.get_children():
		if _text_visible(c, text):
			return true
	return false
