extends Node
## Short vibration feedback, honours the user's vibration setting. No-op off mobile.


func tap() -> void:
	_buzz(15)


func hit() -> void:
	_buzz(40)


func heavy() -> void:
	_buzz(90)


func _buzz(ms: int) -> void:
	if OS.has_feature("mobile") and Settings.get_value("vibration"):
		Input.vibrate_handheld(ms)
