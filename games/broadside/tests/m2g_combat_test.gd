extends SceneTree
var checks: int = 0
var failures: int = 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("PASS: " if ok else "FAIL: ",description)
func frames(count: int = 2) -> void:
	for i: int in range(count):
		await physics_frame
		await process_frame
func press(down: bool, echo: bool = false) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_SPACE
	event.pressed = down
	event.echo = echo
	Input.parse_input_event(event)
func run() -> void:
	var game: Node = preload("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	game.start_battle()
	await frames()
	var player: BroadsideShip = game.arena.player
	game.arena.enemy.set_physics_process(false)
	player.set_physics_process(false)
	for weapon: String in ["standard","chain","long","carronade"]:
		for gunner: int in [0,3]:
			var data: Dictionary = CampaignSave.fresh("Timing","Clock")
			data.weapon = weapon
			data.crew = "gunner"
			data.upgrades = {"gunners":gunner}
			Shipyard.apply(player,data)
			player.port.remaining = 0
			player.starboard.remaining = 0.75
			game.hud.sync_batteries()
			check(player.fire_loaded() == 1 and game.hud.port_bar.value == 0 and game.hud.port_state.text != "READY","%s rank %d: only ready port fires, HUD resets immediately" % [weapon,gunner])
			var synced: bool = true
			for frame: int in range(270):
				player.step(1.0/60.0,0,0)
				synced = synced and (game.hud.port_state.text == "READY") == player.port.ready() and (game.hud.starboard_state.text == "READY") == player.starboard.ready()
				synced = synced and is_equal_approx(game.hud.port_bar.value,100*clampf(1-player.port.remaining/player.guns.reload_seconds,0,1))
				if player.starboard.ready():
					var expected: int = (1 if player.port.ready() else 0)+1
					synced = (player.fire_loaded() == expected) and synced
			check(synced,"%s rank %d: 270 frame checks agree with independent live clocks and fire permission" % [weapon,gunner])
	player.port.remaining = 0.0001
	player.starboard.remaining = 1
	game.hud.sync_batteries()
	check("99%" in game.hud.port_state.text and "0.1 s" in game.hud.port_state.text and player.fire_loaded() == 0,"last fraction of reload never says READY, 100 percent or zero seconds")
	player.step(1.0/60,0,0)
	check(game.hud.port_state.text == "READY" and player.fire_loaded() == 1,"same physics tick READY permits firing")
	player.port.remaining = 1
	player.starboard.remaining = 2
	var before: Vector2 = Vector2(player.port.remaining/player.guns.reload_seconds,player.starboard.remaining/player.guns.reload_seconds)
	var changed: CannonStats = player.guns.duplicate()
	changed.reload_seconds *= 0.5
	player.set_cannon_loadout(changed)
	check(Vector2(player.port.remaining/player.guns.reload_seconds,player.starboard.remaining/player.guns.reload_seconds).is_equal_approx(before),"changing loadout preserves each battery's real remaining fraction")
	player.set_physics_process(true)
	game.pause_battle()
	var paused: Vector2 = Vector2(player.port.remaining,player.starboard.remaining)
	await frames(15)
	check(Vector2(player.port.remaining,player.starboard.remaining) == paused,"pause freezes both real clocks")
	game.resume_battle()
	player.port.remaining = 0
	player.starboard.remaining = 0
	press(true)
	await frames(1)
	check(not player.port.ready() and not player.starboard.ready(),"fresh Space consumes both sides")
	await frames(300)
	press(true,true)
	await frames()
	check(player.port.ready() and player.starboard.ready(),"held or echoed Space does not autofire when reloaded")
	press(false)
	press(true)
	await frames(1)
	check(not player.port.ready(),"new Space after release fires again")
	press(false)
	var hostile: BroadsideShip = game.arena.enemy
	hostile.position = player.position+Vector2(180,0)
	await frames()
	var meters: Array[Dictionary] = game.battle_view.enemy_health.meters()
	check(meters.size() == 1 and meters[0].hp == hostile.health,"enemy bar binds actual hull health")
	hostile.take_damage(16)
	meters = game.battle_view.enemy_health.meters()
	check(meters.size() == 1 and meters[0].hp == hostile.health,"enemy damage immediately changes meter data")
	hostile.ability = BossAbility.new("warden")
	game.arena.encounter = game.arena.encounter.duplicate()
	game.arena.encounter.boss_name = "Test Warden"
	meters = game.battle_view.enemy_health.meters()
	check(meters[0].boss and meters[0].width > 94 and meters[0].name == "Test Warden","boss has distinct named larger health bar")
	hostile.take_damage(10000)
	check(game.battle_view.enemy_health.meters().is_empty(),"sunk ship has no health bar")
	game.show_menu()
	game.audio.shutdown()
	OS.delay_msec(150)
	game.queue_free()
	await frames()
	print("M2G COMBAT RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
