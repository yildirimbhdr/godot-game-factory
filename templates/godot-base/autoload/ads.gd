extends Node
## Stable ads API for game code. This default is a mock so games never depend on an ad SDK.
## The ads-admob module replaces this autoload and keeps the same methods and signals.

signal consent_resolved(granted: bool)
signal ad_started
signal ad_finished

var provider := "none"


func is_mock() -> bool:
	return provider == "none"


func uses_test_units() -> bool:
	return true


func is_rewarded_ready() -> bool:
	return true


func show_interstitial() -> void:
	print("[ads] interstitial (mock)")


## Call once per completed level; the real module applies the cadence rules and returns true if it showed an ad.
func try_interstitial(level_number: int) -> bool:
	print("[ads] try_interstitial after level ", level_number, " (mock)")
	return false


## Usage: var granted: bool = await Ads.show_rewarded()
func show_rewarded() -> bool:
	print("[ads] rewarded (mock) -> granted")
	await get_tree().process_frame
	return true


func privacy_options_required() -> bool:
	return false


func show_privacy_options() -> void:
	pass
