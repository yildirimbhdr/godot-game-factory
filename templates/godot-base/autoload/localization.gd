extends Node
## Translations without any import step. Keys are the English texts used in scenes and code, so every Label/Button
## translates itself and a missing entry simply shows the English text.
## Add a language by adding a block to assets/i18n/strings.json ({"de": {"Play": "Spielen"}}) and its code to LANGUAGES.
## Texts built with format strings need the format as the key: `tr("Best %d") % best`.

const STRINGS_PATH := "res://assets/i18n/strings.json"
const LANGUAGES := ["en", "tr"]

var _loaded: Array[String] = []


func _ready() -> void:
	_load_strings()
	apply(Settings.get_value("language"))
	Settings.changed.connect(func(key: String) -> void:
		if key == "language":
			apply(Settings.get_value("language")))


## `choice` is "auto" (device language, English when unsupported) or a language code.
func apply(choice: String) -> void:
	var code := choice
	if choice == "auto" or not LANGUAGES.has(choice):
		code = OS.get_locale_language()
		if not LANGUAGES.has(code):
			code = "en"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--playtest=") and choice == "auto":
			code = "en"   # scenarios match on English texts; a scenario that sets a language explicitly keeps it
	if OS.has_environment("GF_LANG"):
		code = OS.get_environment("GF_LANG")   # debug aid: screenshots in another language
	TranslationServer.set_locale(code)


## Next value when the language button is pressed: auto -> en -> tr -> auto.
func next_choice(current: String) -> String:
	var order := ["auto"] + LANGUAGES
	return order[(order.find(current) + 1) % order.size()]


func choice_label(choice: String) -> String:
	return tr("Auto") if choice == "auto" else choice.to_upper()


func _load_strings() -> void:
	var f := FileAccess.open(STRINGS_PATH, FileAccess.READ)
	if f == null:
		return
	var data: Variant = JSON.parse_string(f.get_as_text())
	if not data is Dictionary:
		push_error("localization: %s is not a JSON object" % STRINGS_PATH)
		return
	for lang: String in data:
		var t := Translation.new()
		t.locale = lang
		for key: String in data[lang]:
			t.add_message(key, data[lang][key])
		TranslationServer.add_translation(t)
		_loaded.append(lang)
