class_name HowTo
extends Control
## First-run "how to play" card. `HowTo.show_once(self, "play", "Tap to score!")` from the game scene shows it the first
## time only (saved as howto_<key>); the text goes through tr(). It dims the game, so taps cannot start the run underneath.
## Playtests skip it unless the scenario sets `{"do": "setting", "key": "force_howto", "value": true}` (see playtest/howto.json).


static func show_once(parent: Node, key: String, text: String) -> void:
	var seen_key := "howto_" + key
	if Settings.get_value(seen_key):
		return
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--playtest=") and not Settings.get_value("force_howto"):
			return
	var card := HowTo.new()
	card.name = "HowTo"
	card.set_anchors_preset(Control.PRESET_FULL_RECT)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.process_mode = Node.PROCESS_MODE_ALWAYS
	var layer := CanvasLayer.new()
	layer.layer = 80
	layer.add_child(card)
	parent.add_child(layer)
	card._build(text, seen_key)


func _build(text: String, seen_key: String) -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 64)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 48)
	margin.add_child(column)
	var label := Label.new()
	label.text = tr(text)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size.x = 700
	column.add_child(label)
	var ok := UIButton.new()
	ok.text = tr("Got it")
	ok.pressed.connect(func() -> void:
		Settings.set_value(seen_key, true)
		get_parent().queue_free())
	column.add_child(ok)
	panel.pivot_offset = panel.size / 2.0
	panel.scale = Vector2.ONE * 0.9
	panel.modulate.a = 0.0
	var t := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(panel, "modulate:a", 1.0, 0.25)
	t.tween_property(panel, "scale", Vector2.ONE, 0.3)
