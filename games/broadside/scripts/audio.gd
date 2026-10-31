extends Node
const Synth = preload("res://scripts/audio_synth.gd")
@export var config: BroadsideAudioConfig = preload("res://data/audio.tres")
var music_player: AudioStreamPlayer
var music_tracks: Dictionary = {}
var music_mix: Dictionary = {"harbor":1.0,"battle":0.0,"boss":0.0}
var music_context: String = "harbor"
var ocean_player: AudioStreamPlayer
var wake_player: AudioStreamPlayer
var sounds: Dictionary = {}
var music_level: float = 0.65
var sfx_level: float = 0.8
var music_muted: bool = false
var sfx_muted: bool = false
var battle: bool = false
var ducked: bool = false
var music_target: float = -19.0
var last_frames: Dictionary = {}
var settings_path: String = "user://audio_settings.cfg"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus: String in ["Music","SFX"]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count-1,bus)
	load_settings()
	for mode: String in ["harbor","battle","boss"]:
		music_tracks[mode] = make_player(Synth.music(config,mode),"Music")
		music_tracks[mode].volume_db = -60
	for player: AudioStreamPlayer in music_tracks.values(): player.play()
	music_player = music_tracks.harbor
	for kind: String in config.effect_gains:
		sounds[kind] = Synth.effect(kind,config.sample_rate)
	ocean_player = make_player(Synth.effect("ocean",config.sample_rate),"SFX")
	ocean_player.volume_db = config.ambience_db
	ocean_player.play()
	wake_player = make_player(Synth.effect("wake",config.sample_rate),"SFX")
	wake_player.volume_db = -60
	wake_player.play()
	set_battle(false)

func make_player(stream: AudioStream, bus: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = bus
	add_child(player)
	return player

func _process(delta: float) -> void:
	var target: float = music_target - (8.0 if ducked else 0.0)
	for mode: String in music_tracks:
		music_mix[mode] = move_toward(float(music_mix[mode]),1.0 if mode == music_context else 0.0,delta/maxf(config.transition_seconds,0.05))
		music_tracks[mode].volume_db = target+linear_to_db(maxf(0.00001,float(music_mix[mode])))

func set_battle(active: bool) -> void:
	battle = active
	music_target = config.combat_music_db if battle else config.menu_music_db
	set_context("battle" if active else "harbor")

func set_context(mode: String) -> void:
	if not music_tracks.has(mode): return
	music_context = mode
	music_player = music_tracks[mode]

func set_motion(ratio: float, delta: float) -> void:
	var target: float = lerpf(-50.0,-24.0,clampf(ratio,0,1)) if battle and not ducked else -60.0
	wake_player.volume_db = move_toward(wake_player.volume_db,target,30.0*delta)

func play_effect(kind: String, gain: float = 1.0) -> void:
	if not sounds.has(kind) or get_child_count() >= 24:
		return
	# Layer volleys once per tick rather than stacking six identical booms.
	var frame: int = Engine.get_physics_frames()
	if last_frames.get(kind,-1) == frame:
		return
	last_frames[kind] = frame
	var player: AudioStreamPlayer = make_player(sounds[kind],"SFX")
	player.process_mode = Node.PROCESS_MODE_ALWAYS if kind in ["select","victory","defeat","sink"] else Node.PROCESS_MODE_PAUSABLE
	player.volume_db = float(config.effect_gains[kind]) + linear_to_db(maxf(gain,0.01))
	player.finished.connect(player.queue_free)
	player.play()

func apply_levels() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"),linear_to_db(maxf(music_level,0.0001)))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"),linear_to_db(maxf(sfx_level,0.0001)))
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"),music_muted or music_level <= 0)
	AudioServer.set_bus_mute(AudioServer.get_bus_index("SFX"),sfx_muted or sfx_level <= 0)

func clear_effects() -> void:
	for child: Node in get_children():
		if child is AudioStreamPlayer and child not in music_tracks.values() and child not in [ocean_player,wake_player]:
			child.stop()
			child.queue_free()

func load_settings() -> void:
	var settings := ConfigFile.new()
	if settings.load(settings_path) == OK:
		var music: Variant = settings.get_value("audio","music",music_level)
		var sfx: Variant = settings.get_value("audio","sfx",sfx_level)
		if music is float or music is int:
			music_level = clampf(float(music),0,1) if is_finite(float(music)) else 0.65
		if sfx is float or sfx is int:
			sfx_level = clampf(float(sfx),0,1) if is_finite(float(sfx)) else 0.8
		music_muted = settings.get_value("audio","music_muted",false) == true
		sfx_muted = settings.get_value("audio","sfx_muted",false) == true
	apply_levels()

func save_settings() -> void:
	apply_levels()
	var settings := ConfigFile.new()
	settings.set_value("audio","music",music_level)
	settings.set_value("audio","sfx",sfx_level)
	settings.set_value("audio","music_muted",music_muted)
	settings.set_value("audio","sfx_muted",sfx_muted)
	var error: Error = settings.save(settings_path)
	if error != OK:
		push_warning("Audio preferences could not be saved: %s" % error_string(error))

func shutdown() -> void:
	for child: Node in get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
	sounds.clear()

func _exit_tree() -> void:
	shutdown()
