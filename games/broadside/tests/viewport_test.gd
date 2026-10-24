extends SceneTree
var checks: int = 0
var failures: int = 0
var game: Node

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print("PASS: " if ok else "FAIL: ",message)

func frames(count: int) -> void:
	for i: int in range(count):
		await physics_frame
		await process_frame

func tap(code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await frames(1)
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await frames(1)

func layout_check() -> void:
	var view: Control = game.battle_view
	var field: Rect2 = view.battlefield.get_global_rect()
	var footer: Rect2 = game.hud.get_global_rect()
	check(is_equal_approx(field.end.y,footer.position.y) and not field.intersects(footer),"battlefield and footer share an edge with zero overlap")
	check(Vector2(view.world.size).is_equal_approx(field.size),"render target matches only the actual battlefield")
	check(game.arena.get_viewport() == view.world and game.hud.get_viewport() == root,"world and footer render in separate viewports")
	check(absf(root.get_final_transform().x.length()/root.get_final_transform().y.length()-1.0) < 0.001,"canvas scales uniformly without distorting ships")
	game.arena.enemy.position = game.arena.player.position + Vector2(0,5000)
	await frames(2)
	var markers: Array[Dictionary] = game.indicators.collect_markers()
	check(markers.size() == 1 and markers[0].position.y+18 < field.size.y,"bottom enemy marker stays entirely above console")
	print("LAYOUT: window=",root.size," battlefield=",field," footer=",footer," render=",view.world.size)

func run() -> void:
	game = preload("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	game.display.settings_path = "user://viewport_test_display.cfg"
	game.start_battle()
	game.arena.player.set_physics_process(false)
	game.arena.enemy.set_physics_process(false)
	await frames(30)
	check(game.battle_view.chrome.title.text == "THE SABLE CHANNEL" and game.battle_view.chrome.title.modulate.a > 0.9,"location data appears in entry title")
	check(game.arena.camera.zoom == Vector2.ONE*0.72,"camera uses configurable 0.72 zoom")
	game.pause_battle()
	var elapsed: float = game.battle_view.chrome.elapsed
	await frames(60)
	check(game.battle_view.chrome.elapsed == elapsed,"pause freezes location fade")
	check("The Sable Channel" in game.panel.find_children("*","Label",true,false)[2].text,"pause menu retains location name")
	game.resume_battle()
	await frames(150)
	check(game.battle_view.chrome.title.modulate.a == 0,"entry title fades within 2.8 seconds and stays gone")
	for resolution: Vector2i in [Vector2i(800,450),Vector2i(1280,720),Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(2560,1080)]:
		root.size = resolution
		await frames(5)
		await layout_check()
	# Test the actual settings control and restore path; no unhandled Space fire.
	game.pause_battle()
	game.show_settings()
	game.panel.fullscreen_toggle.grab_focus()
	await tap(KEY_SPACE)
	check(game.display.fullscreen and paused,"keyboard settings toggle enables fullscreen while combat remains paused")
	if DisplayServer.get_name() != "headless":
		await create_timer(0.5,true,false,true).timeout
		check(root.mode == Window.MODE_FULLSCREEN,"native window enters fullscreen")
		print("NATIVE FULLSCREEN: ",root.size," monitor=",DisplayServer.screen_get_size())
	var config := ConfigFile.new()
	check(config.load(game.display.settings_path) == OK and config.get_value("display","fullscreen") == true,"display preference persists to user data")
	game.display.set_fullscreen(false,false)
	game.display.load_settings()
	check(game.display.fullscreen,"saved fullscreen preference restores")
	await tap(KEY_SPACE)
	check(not game.display.fullscreen,"keyboard settings restores Windowed")
	if DisplayServer.get_name() != "headless":
		await create_timer(0.5,true,false,true).timeout
		check(root.mode == Window.MODE_WINDOWED,"native window returns from fullscreen")
	check(get_nodes_in_group("projectiles").is_empty(),"settings Space never leaks to combat")
	var point: Vector2 = root.get_final_transform() * game.panel.fullscreen_toggle.get_global_rect().get_center()
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = point
	click.global_position = point
	click.pressed = true
	Input.parse_input_event(click)
	await frames(1)
	click = click.duplicate()
	click.pressed = false
	Input.parse_input_event(click)
	await frames(2)
	check(game.display.fullscreen,"mouse hit testing can enable fullscreen after resizing")
	await tap(KEY_SPACE)
	check(not game.display.fullscreen,"focused display control restores Windowed after a mouse toggle")
	await tap(KEY_ESCAPE)
	game.resume_battle()
	await frames(5)
	await layout_check()
	var destination := EncounterStats.new()
	destination.location_name = "Reefrunner Pass"
	destination.location_subtitle = "Test destination"
	game.start_battle(destination)
	await frames(2)
	check(game.battle_view.chrome.title.text == "REEFRUNNER PASS","a supplied encounter can reuse the title without changing HUD code")
	DirAccess.remove_absolute(game.display.settings_path)
	# Retire the newly created subviewport before shutting down rendering/audio.
	game.show_menu()
	await frames(10)
	OS.delay_msec(150)
	game.audio.shutdown()
	OS.delay_msec(150)
	await frames(3)
	game.queue_free()
	await frames(3)
	print("VIEWPORT RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
