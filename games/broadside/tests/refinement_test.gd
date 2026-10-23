extends SceneTree
const Indicators = preload("res://scripts/enemy_indicators.gd")
var failures: int = 0
var checks: int = 0
var game: Node

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, description: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ",description)
	if not ok:
		failures += 1

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

func run() -> void:
	game = preload("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await frames(2)
	game.start_battle()
	var ship: BroadsideShip = game.arena.player
	game.arena.enemy.set_physics_process(false)
	ship.set_physics_process(false)
	ship.position = Vector2(-800,550)
	ship.speed = 100
	for i: int in range(60):
		ship.step(1.0/60,0,0)
	check(ship.speed > 85 and ship.speed < 100,"one second without throttle preserves substantial momentum")
	ship.speed = ship.hull.top_speed
	ship.turn_velocity = 0
	ship.step(1.0/60,1,1)
	check(ship.turn_velocity > 0 and ship.turn_velocity < ship.hull.turn_rate*0.1,"rudder builds turn rate gradually")
	for i: int in range(60):
		ship.step(1.0/60,1,1)
	check(ship.turn_velocity <= 0.85 and ship.turn_velocity > 0.7,"full-speed turn reaches slower configured cap")
	check(ship.drift.length() > 0 and ship.drift.length() <= ship.hull.max_drift,"sideways momentum exists but remains limited")
	ship.speed = 0
	ship.turn_velocity = 0
	ship.step(1.0,0,1)
	check(ship.turn_velocity <= ship.hull.turn_rate*0.13,"stationary rudder has little authority")
	for i: int in range(120):
		ship.step(1.0/60,-1,0)
	check(absf(ship.speed) <= 22.01,"reverse speed is limited")
	check(is_equal_approx(game.arena.camera.zoom.x,0.8),"camera reveals 25 percent more width")
	check(ship.guns.projectile_speed == 300 and ship.guns.projectile_lifetime*300 >= 860,"slower cannonballs retain useful range")
	check(400.0/ship.guns.projectile_speed > 1.3,"medium-range travel exceeds 1.3 seconds")
	# Clear-water paired scenario: identical fixed volley, change only the human's lead.
	var healths: Array[float] = []
	for lead: bool in [false,true]:
		game.start_battle()
		await frames(2)
		var target: BroadsideShip = game.arena.player
		var shooter: BroadsideShip = game.arena.enemy
		shooter.set_physics_process(false)
		shooter.position = Vector2(-600,365 if lead else 500)
		shooter.rotation = 0
		target.position = Vector2(-300,500)
		target.rotation = 0
		target.speed = 150
		await frames(2)
		shooter.fire_loaded()
		await frames(90)
		healths.append(target.health)
	check(healths[0] == 100,"moving ship dodges a medium-range volley aimed at its old position")
	check(healths[1] < 100,"manually leading the same moving target produces a real collision")
	healths.clear()
	for lead: bool in [false,true]:
		game.start_battle()
		await frames(2)
		var target: BroadsideShip = game.arena.player
		var shooter: BroadsideShip = game.arena.enemy
		shooter.set_physics_process(false)
		shooter.position = Vector2(-850,338 if lead else 600)
		shooter.rotation = 0
		target.position = Vector2(-250,600)
		target.rotation = 0
		target.speed = 150
		await frames(2)
		shooter.fire_loaded()
		await frames(150)
		healths.append(target.health)
	check(healths[0] == 100,"long-range volley can be dodged through movement")
	check(healths[1] < 100,"long-range manual lead can hit without homing")
	var viewport := Vector2(1280,720)
	check(Indicators.marker(Vector2(400,300),viewport).is_empty(),"visible enemy has no indicator")
	for point: Vector2 in [Vector2(-200,360),Vector2(1500,360),Vector2(640,-300),Vector2(640,1000),Vector2(-300,-500),Vector2(1600,1100)]:
		var marker: Dictionary = Indicators.marker(point,viewport)
		check(Rect2(20,110,1240,590).has_point(marker.position),"offscreen marker stays on safe edges for %s" % point)
		check(marker.direction.dot((point-viewport*0.5).normalized()) > 0.999,"indicator points toward actual position")
	var audio: Node = game.audio
	var indicators: Control = game.ui.get_child(game.ui.get_child_count()-1)
	game.arena.enemy.position = Vector2(10000,10000)
	await frames(2)
	check(indicators.collect_markers().size() == 1,"offscreen live enemy produces one marker")
	game.arena.enemy.dead = true
	check(indicators.collect_markers().is_empty(),"destroyed enemy marker disappears")
	game.arena.enemy.dead = false
	game.arena.enemy.position = game.arena.player.position + Vector2(150,0)
	await frames(2)
	check(indicators.collect_markers().is_empty(),"marker disappears when enemy enters camera view")
	audio.settings_path = "user://refinement_test_settings.cfg"
	var stream: AudioStreamWAV = audio.music_player.stream
	check(stream.loop_mode == AudioStreamWAV.LOOP_FORWARD and stream.loop_end == stream.data.size()/2,"music has an exact sample loop")
	check(stream.get_length() > 23 and stream.get_length() < 24,"original 16-bar music loop has expected duration")
	check(abs(stream.data.decode_s16(0)-stream.data.decode_s16(stream.data.size()-2)) < 200,"music seam has no abrupt sample jump")
	check(audio.music_player.playing and audio.ocean_player.playing and audio.wake_player.playing,"all continuous audio players are active")
	for kind: String in audio.config.effect_gains:
		check(audio.sounds[kind] is AudioStreamWAV and audio.sounds[kind].get_length() > 0.05,"synthesized effect exists: "+kind)
	game.pause_battle()
	game.show_settings()
	await frames(2)
	check(paused and root.gui_get_focus_owner() == game.panel.music_slider,"settings from pause keeps combat paused and focuses slider")
	var before: float = audio.music_level
	await tap(KEY_LEFT)
	check(audio.music_level < before,"keyboard adjusts music slider")
	await tap(KEY_DOWN)
	await tap(KEY_SPACE)
	check(audio.music_muted and AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")),"keyboard toggles music mute")
	await tap(KEY_DOWN)
	before = audio.sfx_level
	await tap(KEY_A)
	check(audio.sfx_level < before,"A adjusts SFX slider independently")
	await tap(KEY_DOWN)
	await tap(KEY_ENTER)
	check(audio.sfx_muted and AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")),"keyboard toggles SFX mute")
	var slider_rect: Rect2 = game.panel.sfx_slider.get_global_rect()
	var point: Vector2 = root.get_final_transform() * (slider_rect.position + Vector2(slider_rect.size.x*0.25,slider_rect.size.y*0.5))
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
	await frames(1)
	check(audio.sfx_level >= 0.15 and audio.sfx_level <= 0.35,"mouse adjusts settings slider through GUI hit testing")
	audio.music_level = 0.05
	audio.sfx_level = 0.05
	audio.music_muted = false
	audio.sfx_muted = false
	audio.load_settings()
	check(audio.music_muted and audio.sfx_muted and audio.music_level > 0.05,"audio preferences reload from user data")
	await tap(KEY_ESCAPE)
	check(game.screen == "pause" and paused,"Escape returns from settings to paused menu")
	game.resume_battle()
	check(not paused and not audio.ducked,"resume restores combat and music mix")
	# Do not leave muted settings for the next test or player.
	DirAccess.remove_absolute(audio.settings_path)
	audio.music_muted = false
	audio.sfx_muted = false
	audio.apply_levels()
	audio.shutdown()
	OS.delay_msec(150)
	await frames(3)
	game.queue_free()
	await frames(3)
	print("REFINEMENT RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
