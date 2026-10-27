class_name GlyphIcon
extends GlyphButton
## The same procedurally drawn glyphs as GlyphButton, but a plain picture: no button background, ignores taps.


func _ready() -> void:
	super()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	flat = true
	custom_minimum_size = Vector2(110, 110)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
