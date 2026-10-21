extends Control

@onready var _music: HSlider = %MusicSlider
@onready var _sfx: HSlider = %SfxSlider
@onready var _vibration: Button = %VibrationButton


func _ready() -> void:
	var has_music := AudioManager.has_music()
	%MusicLabel.visible = has_music
	_music.visible = has_music
	_music.value = Settings.get_value("music_volume")
	_sfx.value = Settings.get_value("sfx_volume")
	_vibration.button_pressed = Settings.get_value("vibration")
	_update_vibration_text()

	_music.value_changed.connect(func(v: float) -> void: Settings.set_value("music_volume", v, false))
	_sfx.value_changed.connect(func(v: float) -> void: Settings.set_value("sfx_volume", v, false))
	_music.drag_ended.connect(func(_changed: bool) -> void: Settings.flush())
	_sfx.drag_ended.connect(func(_changed: bool) -> void:
		Settings.flush()
		AudioManager.play_sfx("ui_click"))
	_vibration.toggled.connect(_on_vibration_toggled)
	%BackButton.pressed.connect(queue_free)


func _on_vibration_toggled(on: bool) -> void:
	Settings.set_value("vibration", on)
	_update_vibration_text()
	if on:
		Haptics.tap()


func _update_vibration_text() -> void:
	_vibration.text = "Vibration: %s" % ("On" if _vibration.button_pressed else "Off")
