extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game: Node = preload("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	var info := EncounterStats.new()
	info.campaign = true
	info.layout = 4
	info.weather = "stormy"
	info.theme = 3
	info.enemy_roles.assign(["regent","hunter","raider"])
	game.start_battle(info)
	await create_timer(1).timeout
	var times: Array[float] = []
	var start: int = Time.get_ticks_usec()
	var previous: int = start
	while Time.get_ticks_usec()-start < 15000000:
		await process_frame
		var now: int = Time.get_ticks_usec()
		times.append((now-previous)/1000.0)
		previous = now
		game.arena.player.health = 10000
		for enemy: BroadsideShip in game.arena.enemies: enemy.health = 10000
	var fps: float = times.size()*1000000.0/(Time.get_ticks_usec()-start)
	times.sort()
	print("M2G PERFORMANCE: 15s storm / three enemies / live audio; FPS %.1f; p95 %.2f ms; peak %.2f ms; renderer %s" % [fps,times[int(times.size()*0.95)],times[-1],RenderingServer.get_video_adapter_name()])
	game.quit_game()
