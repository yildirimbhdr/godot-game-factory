class_name UIButton
extends Button
## Button with touch-sized minimum height, press/release scale feedback, click sound and haptic.
## Use this instead of plain Button everywhere.

@export var click_sound := "ui_click"

const MIN_HEIGHT := 150.0


func _ready() -> void:
	custom_minimum_size.y = maxf(custom_minimum_size.y, MIN_HEIGHT)
	resized.connect(func() -> void: pivot_offset = size / 2.0)
	pivot_offset = size / 2.0
	pressed.connect(_on_pressed)
	button_down.connect(func() -> void: _scale_to(0.94, 0.06))
	button_up.connect(func() -> void: _scale_to(1.0, 0.18))


func _on_pressed() -> void:
	AudioManager.play_sfx(click_sound)
	Haptics.tap()


func _scale_to(target: float, duration: float) -> void:
	create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT) \
		.tween_property(self, "scale", Vector2.ONE * target, duration)
