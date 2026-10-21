extends Node
## Music and SFX playback on "Music" and "SFX" buses, volumes driven by Settings.
## Sounds are looked up by name: res://assets/audio/sfx/<name>.(ogg|wav|mp3), same for music/.
## A missing SFX is skipped with a one-time warning and listed in `missing`, so the playtest can
## fail on it. Music is optional: a game without music files simply has no music, and the
## settings screen hides the music slider (see has_music()).

const SFX_DIR := "res://assets/audio/sfx/"
const MUSIC_DIR := "res://assets/audio/music/"
const EXTENSIONS := ["ogg", "wav", "mp3"]
const POOL_SIZE := 8
## Optional per-track loudness gains written by scripts/add_music.py.
const GAINS_PATH := "res://assets/audio/music_gains.gd"

var missing: Array[String] = []

var _pool: Array[AudioStreamPlayer] = []
var _music: AudioStreamPlayer
var _music_name := ""
var _cache := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus("Music")
	_ensure_bus("SFX")
	_add_master_limiter()
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_pool.append(p)
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	add_child(_music)
	Settings.changed.connect(func(_key: String) -> void: _apply_volumes())
	_apply_volumes()


## Stop everything on exit so the audio server releases its playbacks (no leak warnings).
func _exit_tree() -> void:
	_music.stop()
	_music.stream = null
	for p in _pool:
		p.stop()
		p.stream = null


## `pitch` > 1 raises the sound (e.g. rising notes for a combo); jitter adds a random +-offset.
func play_sfx(sound: String, pitch_jitter := 0.0, pitch := 1.0) -> void:
	var stream := _load(SFX_DIR, sound)
	if stream == null:
		return
	for p in _pool:
		if not p.playing:
			p.stream = stream
			p.pitch_scale = pitch + randf_range(-pitch_jitter, pitch_jitter)
			p.play()
			return


## True if the game ships any music, so UI can decide whether to show music controls.
func has_music() -> bool:
	for entry in ResourceLoader.list_directory(MUSIC_DIR):
		if entry.get_extension() in EXTENSIONS or entry.ends_with(".import"):
			return true
	return false


func play_music(sound: String, fade := 0.5) -> void:
	if sound == _music_name and _music.playing:
		return
	var stream := _load(MUSIC_DIR, sound, false)
	if stream == null:
		return
	_music_name = sound
	if "loop" in stream:
		stream.loop = true
	elif "loop_mode" in stream:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = int(stream.get_length() * stream.mix_rate)
	_music.stream = stream
	_music.volume_db = -40.0
	_music.play()
	create_tween().tween_property(_music, "volume_db", _music_gain_db(sound), fade)


func _music_gain_db(sound: String) -> float:
	if not ResourceLoader.exists(GAINS_PATH):
		return 0.0
	return float(load(GAINS_PATH).GAINS.get(sound, 0.0))


func stop_music(fade := 0.5) -> void:
	_music_name = ""
	var t := create_tween()
	t.tween_property(_music, "volume_db", -40.0, fade)
	t.tween_callback(_music.stop)


func _load(dir: String, sound: String, required := true) -> AudioStream:
	var key := dir + sound
	if _cache.has(key):
		return _cache[key]
	for ext in EXTENSIONS:
		var path := "%s%s.%s" % [dir, sound, ext]
		if ResourceLoader.exists(path):
			_cache[key] = load(path)
			return _cache[key]
	if required and not key in missing:
		missing.append(key)
		print("[audio] missing sound: ", key)
	_cache[key] = null
	return null


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var idx := AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, "Master")


## Overlapping sounds can sum past full scale; a limiter on Master prevents clipping.
func _add_master_limiter() -> void:
	var limiter := AudioEffectHardLimiter.new()
	limiter.ceiling_db = -1.0
	AudioServer.add_bus_effect(0, limiter)


func _apply_volumes() -> void:
	_set_bus_linear("Music", Settings.get_value("music_volume"))
	_set_bus_linear("SFX", Settings.get_value("sfx_volume"))


func _set_bus_linear(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_volume_db(idx, linear_to_db(linear) if linear > 0.001 else -80.0)
	AudioServer.set_bus_mute(idx, linear <= 0.001)
