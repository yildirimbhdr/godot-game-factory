extends Node
## Persistent user settings and small key/value save data (user://settings.cfg).

signal changed(key: String)

const PATH := "user://settings.cfg"
const DEFAULTS := {
	"music_volume": 0.8,
	"sfx_volume": 1.0,
	"vibration": true,
	"best_score": 0,
}

var _cfg := ConfigFile.new()
## Playtests never read or write saved data, so every run starts clean.
var _ephemeral := false


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--playtest="):
			_ephemeral = true
	if not _ephemeral:
		_cfg.load(PATH)


func get_value(key: String) -> Variant:
	return _cfg.get_value("settings", key, DEFAULTS.get(key))


## Pass save_now = false for rapid updates (sliders) and call flush() when done.
func set_value(key: String, value: Variant, save_now := true) -> void:
	_cfg.set_value("settings", key, value)
	if save_now:
		flush()
	changed.emit(key)


func flush() -> void:
	if not _ephemeral:
		_cfg.save(PATH)
