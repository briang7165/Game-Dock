extends SceneTree
var checks: int = 0
var failures: int = 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("PASS: " if ok else "FAIL: ",description)
func frames(count: int) -> void:
	for i: int in range(count):
		await physics_frame
		await process_frame
func run() -> void:
	var data: Dictionary = CampaignSave.fresh("Captain Test","The Compass",0,123)
	var safe: bool = true
	var bounded: bool = true
	var deterministic: bool = true
	var spawns: Array[Vector2] = [Vector2(-290,30),Vector2(290,-70),Vector2(700,-70),Vector2(450,500)]
	for chapter: int in range(1,1001):
		data.chapter = chapter
		for route: int in range(3):
			data.route = route
			for stop: int in range(5):
				data.stop = stop
				var info: EncounterStats = VoyageDirector.encounter(data)
				bounded = bounded and info.enemy_roles.size() <= 3 and info.difficulty <= 6
				deterministic = deterministic and VoyageDirector.islands(info) == VoyageDirector.islands(VoyageDirector.encounter(data))
				for island: Vector2 in VoyageDirector.islands(info):
					for spawn: Vector2 in spawns: safe = safe and island.distance_to(spawn) > 180
	check(safe,"15000 generated encounters keep all spawns clear of rocks")
	check(bounded,"1000 chapters bound enemy count and difficulty")
	check(deterministic,"save seed and route reproduce the same battlefield")
	data = CampaignSave.fresh("Test","Test",0,123)
	for stop: int in range(3):
		data.stop = stop
		check(VoyageDirector.encounter(data).enemy_roles.size() == 1,"first three Trade Winds encounters remain solo duels")
	data.stop = 4
	var names: Array[String] = []
	for chapter: int in range(1,4):
		data.chapter = chapter
		names.append(VoyageDirector.encounter(data).boss_name)
	check(names[0] != names[1] and names[1] != names[2],"three chapter boss identities rotate")
	data.stop = 0
	data.route = 0
	var reward: int = VoyageDirector.reward(data)
	data.route = 2
	check(VoyageDirector.reward(data) > reward,"danger route offers greater prize gold")
	data.crew = "gunner"
	check(Shipyard.guns_for(data).reload_seconds < 3,"gunner berth changes reload")
	data.crew = "navigator"
	check(Shipyard.hull_for(data).top_speed > 165,"navigator berth changes sailing")
	data.crew = "quartermaster"
	check(VoyageDirector.reward(data) > roundi(reward*1.7),"quartermaster changes rewards")
	data.weapon = "chain"
	check(Shipyard.guns_for(data).damage == 10 and Shipyard.guns_for(data).slow_seconds == 2,"chain shot trades damage for temporary rigging effect")
	var save := CampaignSave.new()
	save.path = "user://odyssey_test.json"
	var legacy: Dictionary = CampaignSave.fresh("Test","Test",0,123)
	for key: String in ["crew","ships_sunk","gold_earned","journal","salvage","weapon"]: legacy.erase(key)
	check(save.commit(legacy) and save.load_game() and Shipyard.guns_for(save.data).damage == 16,"M2-A save without later fields loads with safe defaults")
	save.begin_encounter(2)
	save.begin_encounter(0)
	check(save.data.route == 2 and save.data.attempt == 1,"resuming cannot reroll an active route or attempt")
	save.settle(false,0,0)
	check(not save.data.active and save.data.salvage == 1,"defeat returns salvage and unlocks safer route")
	for i: int in range(100):
		save.begin_encounter(0)
		save.settle(true,40,1)
	check(save.data.chapter == 21 and save.data.bosses == 20 and save.data.journal.size() == 8,"100 victories advance twenty chapters with bounded journal")
	data = save.data.duplicate(true)
	data.chapter = 1000000000
	data.stop = 4
	save.commit(data)
	save.begin_encounter()
	save.settle(true,40)
	check(save.data.chapter == 1 and save.data.gold <= 1000000000,"chapter rollover and currency stay in safe integer bounds")
	var game: Node = preload("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	game.campaign.save = save
	data = save.data.duplicate(true)
	data.chapter = 3
	data.stop = 3
	data.health = 60
	save.commit(data)
	game.campaign.show_chart()
	game.campaign.start_travel(2)
	var escape := InputEventKey.new()
	escape.physical_keycode = KEY_ESCAPE
	escape.pressed = true
	Input.parse_input_event(escape)
	await frames(2)
	check(game.screen == "battle" and game.arena.enemies.size() == 3,"Escape skips travel into a three-ship encounter")
	escape = escape.duplicate()
	escape.pressed = false
	Input.parse_input_event(escape)
	var arena: Node = game.arena
	var hostile: BroadsideShip = arena.enemies[0]
	hostile.position = Vector2(2200,0)
	hostile.warning = 0
	await frames(20)
	check(hostile.warning == 0 and hostile.port.ready(),"offscreen campaign enemy cannot begin firing warning")
	for ship: BroadsideShip in arena.enemies: ship.set_physics_process(false)
	arena.player.set_physics_process(false)
	arena.enemies[0].take_damage(10000)
	await frames(50)
	check(not arena.finished and game.screen == "battle","sinking one enemy does not end a fleet battle")
	arena.enemies[1].take_damage(10000)
	arena.enemies[2].take_damage(10000)
	await frames(60)
	check(game.screen == "campaign_result" and save.data.stop == 4,"last hostile ends battle and advances once")
	check(int(save.data.ships_sunk) == 104,"journal counts all three fleet kills")
	game.campaign.show_harbor()
	game.campaign.appoint_crew("carpenter")
	check(save.data.crew == "carpenter","earned crew appointment persists")
	game.campaign.start_travel(0)
	game.campaign.enter_battle()
	check(game.arena.enemy.health <= 160 and game.arena.enemy.tactics.ai_telegraph >= 1.2,"boss health capped with longer readable warning")
	# Exercise the real swept projectile, not only catalog metadata.
	var target: BroadsideShip = game.arena.enemy
	target.set_physics_process(false)
	target.position = Vector2(-100,30)
	game.arena.player.set_physics_process(false)
	var ball: Node2D = preload("res://scenes/Cannonball.tscn").instantiate()
	ball.source = game.arena.player
	ball.stats = Shipyard.guns_for({"hull":"sloop","upgrades":{},"weapon":"chain"})
	ball.position = Vector2(-140,30)
	ball.direction = Vector2.RIGHT
	game.arena.add_child(ball)
	await frames(12)
	check(target.rigging_slow > 0 and target.health < target.hull.max_health,"real chain projectile damages and impairs rigging")
	target.rigging_slow = 0.2
	target.step(0.3,0,0)
	check(target.rigging_slow == 0,"rigging impairment expires without permanent movement lock")
	game.campaign.retreat()
	check(save.data.stop == 4 and save.data.health >= 60,"boss retreat retains progress and free seaworthy refit")
	game.campaign.show_harbor()
	await frames(2)
	var scroll: ScrollContainer = game.campaign.status.get_parent().find_child("*",false,false) as ScrollContainer
	# Find the scroll by type; its name is generated by Godot.
	for child: Node in game.campaign.status.get_parent().get_children():
		if child is ScrollContainer: scroll = child
	var stock: Node = scroll.get_child(0)
	stock.get_child(stock.get_child_count()-1).grab_focus()
	await frames(5)
	check(scroll.scroll_vertical > 0,"keyboard focus scrolls to the final crew appointment")
	game.show_menu()
	await frames(5)
	game.audio.shutdown()
	OS.delay_msec(150)
	game.queue_free()
	await frames(3)
	for suffix: String in ["",".bak",".tmp"]: DirAccess.remove_absolute(save.path+suffix)
	print("ODYSSEY RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
