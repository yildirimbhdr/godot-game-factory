extends Control

@onready var _music: HSlider = %MusicSlider
@onready var _sfx: HSlider = %SfxSlider
@onready var _vibration: IconButton = %VibrationButton
@onready var _music_toggle: IconButton = %MusicLabel
@onready var _sfx_toggle: IconButton = %SfxIcon


func _ready() -> void:
	var has_music := AudioManager.has_music()
	_music_toggle.visible = has_music
	_music.visible = has_music
	_music.value = Settings.get_value("music_volume")
	_sfx.value = Settings.get_value("sfx_volume")
	_music_toggle.set_pressed_no_signal(_music.value > 0.001)
	_sfx_toggle.set_pressed_no_signal(_sfx.value > 0.001)
	_music_toggle._refresh()
	_sfx_toggle._refresh()
	_vibration.button_pressed = Settings.get_value("vibration")

	_music.value_changed.connect(func(v: float) -> void: _volume_changed("music_volume", v, _music_toggle))
	_sfx.value_changed.connect(func(v: float) -> void: _volume_changed("sfx_volume", v, _sfx_toggle))
	_music_toggle.toggled.connect(func(on: bool) -> void: _toggle_mute("music_volume", _music, on))
	_sfx_toggle.toggled.connect(func(on: bool) -> void: _toggle_mute("sfx_volume", _sfx, on))
	_music.drag_ended.connect(func(_changed: bool) -> void: Settings.flush())
	_sfx.drag_ended.connect(func(_changed: bool) -> void:
		Settings.flush()
		AudioManager.play_sfx("ui_click"))
	_vibration.toggled.connect(_on_vibration_toggled)
	%BackButton.pressed.connect(queue_free)
	# Required by Google/Apple where a consent form applies (EEA, UK); hidden elsewhere.
	%PrivacyButton.visible = Ads.privacy_options_required()
	%PrivacyButton.pressed.connect(Ads.show_privacy_options)
	%PrivacyButton.add_to_group("btn_privacy")


func _on_vibration_toggled(on: bool) -> void:
	Settings.set_value("vibration", on)
	if on:
		Haptics.tap()


## The speaker/note icon is a mute switch: tapping it silences that channel at once and shows the muted
## glyph; tapping again restores the previous volume. Dragging the slider to zero shows the muted glyph too.
func _toggle_mute(key: String, slider: HSlider, on: bool) -> void:
	if on:
		var back: float = Settings.get_value(key + "_before_mute")
		slider.value = back if back > 0.001 else 0.8
	else:
		if slider.value > 0.001:
			Settings.set_value(key + "_before_mute", slider.value, false)
		slider.value = 0.0
	Settings.flush()
	if on:
		AudioManager.play_sfx("ui_click")


func _volume_changed(key: String, value: float, toggle: IconButton) -> void:
	Settings.set_value(key, value, false)
	toggle.set_pressed_no_signal(value > 0.001)
	toggle._refresh()
