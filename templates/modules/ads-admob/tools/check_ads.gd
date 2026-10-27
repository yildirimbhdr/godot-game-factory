extends SceneTree
## Headless check of the interstitial cadence (mock path): godot --headless --path . -s tools/check_ads.gd

func _initialize() -> void:
	var ads: Node = load("res://autoload/ads.gd").new()
	var shown := []
	for level in range(1, 13):
		if ads.try_interstitial(level):
			shown.append(level)
		# pretend the player spent the minimum gap between levels
		ads._last_interstitial_msec -= Ads_MIN_GAP_MSEC
	print("interstitial after levels: ", shown)
	var ok: bool = shown == [4, 7, 10]
	print("ADS CADENCE ", "OK" if ok else "FAIL")
	quit(0 if ok else 1)

const Ads_MIN_GAP_MSEC := 121000
