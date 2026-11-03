extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var weather: String = args[1] if args.size() > 1 else "stormy"
	if args.size() > 2 and args[2] == "fullscreen": DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	var game: Node = preload("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	var encounter := EncounterStats.new()
	encounter.campaign = true
	encounter.layout = 3
	encounter.theme = 3 if weather == "stormy" else (2 if weather == "misty" else 0)
	encounter.weather = weather
	encounter.enemy_roles.assign(["regent","hunter","raider"])
	encounter.boss_name = "The Storm Regent"
	game.start_battle(encounter)
	var ship: BroadsideShip = game.arena.player
	var data: Dictionary = CampaignSave.fresh("Rowan Ashford","Brass Finch")
	data.hull = "brig"
	data.upgrades = {"cannons":1,"armor":3,"sails":3,"rudder":3,"lookout":2,"prow":2}
	data.weapon = "chain"
	data.health = 150
	Shipyard.apply(ship,data)
	ship.set_physics_process(false)
	ship.position = Vector2(-100,0)
	for i: int in range(3):
		var enemy: BroadsideShip = game.arena.enemies[i]
		enemy.position = ship.position+[Vector2(340,30),Vector2(120,-230),Vector2(-250,-120)][i]
		enemy.rotation = 0.3+i*0.9
		enemy.health *= 0.65
		enemy.set_physics_process(false)
	game.battle_view.chrome.hide()
	await create_timer(0.6).timeout
	ship.fire_loaded()
	await create_timer(0.18).timeout
	if not (game.battle_view.enemy_health.meters().size() == 3):
		push_error("three readable actual enemy meters")
		quit(1)
		return
	if not (game.hud.port_state.text != "READY"):
		push_error("fired battery display is reloading")
		quit(1)
		return
	if not (ship.visual_upgrades.armor == 3 and ship.guns.gun_count == 3 and ship.guns.slow_seconds > 0):
		push_error("saved fittings reach real render and projectiles")
		quit(1)
		return
	await RenderingServer.frame_post_draw
	var screenshot: Image = root.get_texture().get_image()
	var saved: Error = screenshot.save_png(args[0])
	if saved != OK:
		push_error("Screenshot save failed: "+str(saved))
		quit(1)
		return
	print("PASS: M2G visual fixture ",weather," ",screenshot.get_size()," three meters, armor, 3 ports per side, chain projectiles")
	game.quit_game()
