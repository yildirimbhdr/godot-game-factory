extends Node
## Stable analytics API for game code. This default is a mock (prints only) so games never depend on an SDK.
## The ads-admob module replaces this autoload with Firebase Analytics and keeps the same methods.


func is_mock() -> bool:
	return true


## `params` values: String, int or float. Bools are sent as 0/1.
func log_event(event: String, params := {}) -> void:
	print("[analytics] ", event, " ", params)
