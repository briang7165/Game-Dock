extends SceneTree
## Real-time native audio mixer check: do not use --fixed-fps.
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game: Node = preload("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	game.start_battle()
	game.arena.enemy.set_physics_process(false)
	var audio: Node = game.audio
	var capture := AudioEffectCapture.new()
	capture.buffer_length = 1.0
	AudioServer.add_bus_effect(0,capture)
	var elapsed: float = 0.0
	var peak: float = 0.0
	var energy: float = 0.0
	var samples: int = 0
	var wraps: int = 0
	var prior: float = 0.0
	var kinds: Array = audio.config.effect_gains.keys()
	var index: int = 0
	while elapsed < 26.0:
		await create_timer(0.25).timeout
		elapsed += 0.25
		if index < kinds.size():
			audio.play_effect(kinds[index])
			index += 1
		var position: float = audio.music_player.get_playback_position()
		if position < prior:
			wraps += 1
		prior = position
		var buffer: PackedVector2Array = capture.get_buffer(capture.get_frames_available())
		for frame: Vector2 in buffer:
			peak = maxf(peak,maxf(absf(frame.x),absf(frame.y)))
			energy += frame.length_squared()
			samples += 2
	var rms: float = sqrt(energy/maxi(samples,1))
	var passed: bool = wraps >= 1 and peak > 0.01 and peak < 0.99 and rms > 0.001 and audio.music_player.playing
	print("AUDIO MIX: wraps=%d peak=%.4f rms=%.4f samples=%d" % [wraps,peak,rms,samples])
	print("PASS: native loop and unclipped audible mix" if passed else "FAIL: native audio playback")
	AudioServer.remove_bus_effect(0,0)
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		audio.music_player.stream.save_to_wav(args[0])
	audio.shutdown()
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	quit(0 if passed else 1)
