extends Node
## Stable ads API for game code, backed by AdMob (addons/admob) on Android and iOS.
## Off-device (editor, playtests) every call is a mock, so games never depend on the SDK.
##
## Flow: consent (UMP) -> MobileAds.initialize -> preload rewarded + interstitial.
## Debug builds and builds without live ad unit ids show Google's TEST ads only (never real ones).
## Fill LIVE_UNITS before release; dod_check.py flags empty ids.

signal consent_resolved(granted: bool)
signal ad_started
signal ad_finished

## Real ad unit ids from the AdMob console, per platform: {"android": "ca-app-pub-.../...", "ios": "..."}.
const LIVE_UNITS := {
	"rewarded": {"android": "", "ios": ""},
	"interstitial": {"android": "", "ios": ""},
}
const TEST_UNITS := {
	"rewarded": {"android": "ca-app-pub-3940256099942544/5224354917", "ios": "ca-app-pub-3940256099942544/1712485313"},
	"interstitial": {"android": "ca-app-pub-3940256099942544/1033173712", "ios": "ca-app-pub-3940256099942544/4411468910"},
}

## Interstitial cadence: never before this level, every Nth completed level, never closer than MIN_GAP_SEC.
const INTERSTITIAL_FROM_LEVEL := 4
const INTERSTITIAL_EVERY := 3
const INTERSTITIAL_MIN_GAP_SEC := 120

var provider := "none"
var consent_granted := false

var _native := false
var _initialized := false
var _rewarded: RewardedAd
var _interstitial: InterstitialAd
var _rewarded_loading := false
var _interstitial_loading := false
var _levels_since_ad := 0
var _last_interstitial_msec := -INTERSTITIAL_MIN_GAP_SEC * 1000
var _reward_earned := false
var _bus_was_muted := false


func _ready() -> void:
	_native = OS.get_name() in ["Android", "iOS"]
	if not _native:
		return
	provider = "admob"
	_request_consent()


func is_mock() -> bool:
	return provider == "none"


func uses_test_units() -> bool:
	return OS.is_debug_build() or _unit_id(LIVE_UNITS, "rewarded").is_empty() or _unit_id(LIVE_UNITS, "interstitial").is_empty()


func is_rewarded_ready() -> bool:
	return _rewarded != null if _native else true


## Shows an interstitial now if one is loaded (no cadence check; see try_interstitial).
func show_interstitial() -> void:
	if not _native:
		print("[ads] interstitial (mock)")
		return
	if _interstitial == null:
		_load_interstitial()
		return
	_last_interstitial_msec = Time.get_ticks_msec()
	_levels_since_ad = 0
	_begin_ad()
	_interstitial.show()


## Call once per completed level. Shows an interstitial when the cadence allows; returns true if it did.
func try_interstitial(level_number: int) -> bool:
	_levels_since_ad += 1
	if level_number < INTERSTITIAL_FROM_LEVEL or _levels_since_ad < INTERSTITIAL_EVERY:
		return false
	if Time.get_ticks_msec() - _last_interstitial_msec < INTERSTITIAL_MIN_GAP_SEC * 1000:
		return false
	if not _native:
		print("[ads] interstitial (mock) after level ", level_number)
		_levels_since_ad = 0
		_last_interstitial_msec = Time.get_ticks_msec()
		return true
	if _interstitial == null:
		_load_interstitial()
		return false
	show_interstitial()
	return true


## Usage: var granted: bool = await Ads.show_rewarded()
## False when the ad was not ready, failed, or was closed before the reward.
func show_rewarded() -> bool:
	if not _native:
		print("[ads] rewarded (mock) -> granted")
		await get_tree().process_frame
		return true
	if _rewarded == null:
		_load_rewarded()
		return false
	_reward_earned = false
	var listener := OnUserEarnedRewardListener.new()
	listener.on_user_earned_reward = func(_item: RewardedItem) -> void: _reward_earned = true
	_begin_ad()
	_rewarded.show(listener)
	await ad_finished
	return _reward_earned


## Settings screen button: required by Google/Apple in regions that ask for consent.
func privacy_options_required() -> bool:
	if not _native:
		return OS.has_environment("ADS_FAKE_PRIVACY")   # lets playtests look at the settings button
	var info := UserMessagingPlatform.consent_information
	return info.get_privacy_options_requirement_status() == ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED


func show_privacy_options() -> void:
	if not _native:
		print("[ads] privacy options (mock)")
	else:
		UserMessagingPlatform.show_privacy_options_form(func(_error: FormError) -> void: _resolve_consent())


func _unit_id(table: Dictionary, kind: String) -> String:
	var key := "android" if OS.get_name() == "Android" else "ios"
	return table[kind][key]


func _unit(kind: String) -> String:
	return _unit_id(TEST_UNITS if uses_test_units() else LIVE_UNITS, kind)


func _request_consent() -> void:
	var info := UserMessagingPlatform.consent_information
	info.update(ConsentRequestParameters.new(), _on_consent_info_updated, func(_error: FormError) -> void: _resolve_consent())


func _on_consent_info_updated() -> void:
	if not UserMessagingPlatform.consent_information.get_is_consent_form_available():
		_resolve_consent()
		return
	UserMessagingPlatform.load_consent_form(
		func(form: ConsentForm) -> void:
			var required := UserMessagingPlatform.consent_information.get_consent_status() == ConsentInformation.ConsentStatus.REQUIRED
			if required:
				form.show(func(_error: FormError) -> void: _resolve_consent())
			else:
				_resolve_consent(),
		func(_error: FormError) -> void: _resolve_consent())


func _resolve_consent() -> void:
	var status := UserMessagingPlatform.consent_information.get_consent_status()
	consent_granted = status in [ConsentInformation.ConsentStatus.NOT_REQUIRED, ConsentInformation.ConsentStatus.OBTAINED]
	consent_resolved.emit(consent_granted)
	if not _initialized:
		_initialized = true
		var listener := OnInitializationCompleteListener.new()
		listener.on_initialization_complete = func(_status: InitializationStatus) -> void:
			_load_rewarded()
			_load_interstitial()
		MobileAds.initialize(listener)


func _load_rewarded() -> void:
	if _rewarded_loading or _rewarded != null or not _initialized:
		return
	_rewarded_loading = true
	var load_cb := RewardedAdLoadCallback.new()
	load_cb.on_ad_loaded = func(ad: RewardedAd) -> void:
		_rewarded_loading = false
		ad.full_screen_content_callback = _content_callback(func() -> void:
			_rewarded.destroy()
			_rewarded = null
			_load_rewarded())
		_rewarded = ad
	load_cb.on_ad_failed_to_load = func(error: LoadAdError) -> void:
		_rewarded_loading = false
		push_warning("[ads] rewarded failed to load: " + error.message)
		get_tree().create_timer(30.0).timeout.connect(_load_rewarded)
	RewardedAdLoader.new().load(_unit("rewarded"), AdRequest.new(), load_cb)


func _load_interstitial() -> void:
	if _interstitial_loading or _interstitial != null or not _initialized:
		return
	_interstitial_loading = true
	var load_cb := InterstitialAdLoadCallback.new()
	load_cb.on_ad_loaded = func(ad: InterstitialAd) -> void:
		_interstitial_loading = false
		ad.full_screen_content_callback = _content_callback(func() -> void:
			_interstitial.destroy()
			_interstitial = null
			_load_interstitial())
		_interstitial = ad
	load_cb.on_ad_failed_to_load = func(error: LoadAdError) -> void:
		_interstitial_loading = false
		push_warning("[ads] interstitial failed to load: " + error.message)
		get_tree().create_timer(30.0).timeout.connect(_load_interstitial)
	InterstitialAdLoader.new().load(_unit("interstitial"), AdRequest.new(), load_cb)


## Dismissed and failed-to-show end the ad the same way: destroy it, preload the next, release the game.
func _content_callback(on_done: Callable) -> FullScreenContentCallback:
	var cb := FullScreenContentCallback.new()
	cb.on_ad_dismissed_full_screen_content = func() -> void:
		on_done.call()
		_end_ad()
	cb.on_ad_failed_to_show_full_screen_content = func(error: AdError) -> void:
		push_warning("[ads] failed to show: " + error.message)
		on_done.call()
		_end_ad()
	return cb


func _begin_ad() -> void:
	_bus_was_muted = AudioServer.is_bus_mute(0)
	AudioServer.set_bus_mute(0, true)
	ad_started.emit()


func _end_ad() -> void:
	AudioServer.set_bus_mute(0, _bus_was_muted)
	ad_finished.emit()
