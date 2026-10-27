extends Node
## Stable analytics API for game code, backed by Firebase Analytics (addons/godotx_firebase) on Android and iOS.
## Without the addon, a config file, or off-device it only prints, so games never depend on the SDK.
##
## Nothing is collected until the player's consent is known: the export plugin starts Firebase with collection off
## and consent denied; this autoload turns it on only when Ads reports consent (UMP) as granted.
## Event names follow Firebase's recommended ones (level_start, level_end) so reports fill in without setup.

var _core: Object
var _analytics: Object
var _ready_to_log := false
var _consent := false


func _ready() -> void:
	if not (Engine.has_singleton("GodotxFirebaseCore") and Engine.has_singleton("GodotxFirebaseAnalytics")):
		return
	_core = Engine.get_singleton("GodotxFirebaseCore")
	_analytics = Engine.get_singleton("GodotxFirebaseAnalytics")
	_core.core_initialized.connect(_on_core_initialized)
	_analytics.analytics_initialized.connect(_on_analytics_initialized)
	Ads.consent_resolved.connect(_on_consent)
	_core.initialize()


func is_mock() -> bool:
	return _analytics == null


## `params` values: String, int or float. Bools are sent as 0/1.
func log_event(event: String, params := {}) -> void:
	var clean := {}
	for key in params:
		var v = params[key]
		clean[key] = int(v) if v is bool else v
	if _analytics == null or not _ready_to_log:
		print("[analytics] ", event, " ", clean)
		return
	_analytics.log_event(event, clean)


func _on_core_initialized(success: bool) -> void:
	if success:
		_analytics.initialize()


func _on_analytics_initialized(success: bool) -> void:
	_ready_to_log = success
	_apply_consent()


func _on_consent(granted: bool) -> void:
	_consent = granted
	_apply_consent()


func _apply_consent() -> void:
	if _analytics == null or not _ready_to_log:
		return
	var state := "granted" if _consent else "denied"
	_analytics.set_consent({
		"analytics_storage": state,
		"ad_storage": state,
		"ad_user_data": state,
		"ad_personalization": state,
	})
	_analytics.set_analytics_collection_enabled(_consent)
