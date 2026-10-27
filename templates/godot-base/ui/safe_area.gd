class_name SafeArea
extends MarginContainer
## Keeps its children out of notches, rounded corners and system bars.
## On desktop there is no inset; pass `-- --notch` to simulate one for playtests.

## Extra margin on every side, in viewport pixels.
@export var min_margin := 48

const SIMULATED_NOTCH := Vector4(0, 90, 0, 60) # left, top, right, bottom


func _ready() -> void:
	get_viewport().size_changed.connect(_apply)
	_apply()


func _apply() -> void:
	var insets := Vector4.ZERO
	if OS.has_feature("mobile"):
		insets = _device_insets()
	elif "--notch" in OS.get_cmdline_user_args():
		insets = SIMULATED_NOTCH
	add_theme_constant_override("margin_left", int(maxf(insets.x, min_margin)))
	add_theme_constant_override("margin_top", int(maxf(insets.y, min_margin)))
	add_theme_constant_override("margin_right", int(maxf(insets.z, min_margin)))
	add_theme_constant_override("margin_bottom", int(maxf(insets.w, min_margin)))


func _device_insets() -> Vector4:
	var safe := DisplayServer.get_display_safe_area()
	var screen := Vector2(DisplayServer.screen_get_size())
	var scale_factor := get_viewport_rect().size.x / maxf(1.0, float(DisplayServer.window_get_size().x))
	return Vector4(
		safe.position.x,
		safe.position.y,
		screen.x - safe.end.x,
		screen.y - safe.end.y,
	) * scale_factor
