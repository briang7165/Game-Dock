extends SceneTree
var checks: int = 0
var failures: int = 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("PASS: " if ok else "FAIL: ",description)
func frames(count: int = 3) -> void:
	for i: int in range(count): await process_frame
func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
func tap(code: Key) -> void:
	key(code,true)
	await frames(1)
	key(code,false)
	await frames()
func click(control: Control) -> void:
	var ancestor: Node = control.get_parent()
	while ancestor != null:
		if ancestor is ScrollContainer: ancestor.ensure_control_visible(control)
		ancestor = ancestor.get_parent()
	await frames()
	var point: Vector2 = root.get_final_transform()*control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	Input.parse_input_event(motion)
	await frames()
	var event := InputEventMouseButton.new()
	event.position = point
	event.global_position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	Input.parse_input_event(event)
	await frames(1)
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await frames()
# Standalone harness also runs against the exported PCK, which excludes test scripts.
func run() -> void:
	var save := CampaignSave.new()
	save.path = "user://m2f_voyage_test.json"
	var data: Dictionary = CampaignSave.fresh("Captain Kept","Ship Kept",1,174)
	data.gold = 1234
	data.salvage = 16
	data.fleet.brig = FleetState.bare("brig")
	data.fleet.brig.upgrades.rudder = 2
	data.fleet.brig.ship = "Brass Finch"
	data.chapter = 2
	data.stop = 3
	data.active = true
	data.route = 2
	data.erase("progression")
	save.commit(data)
	var before: Dictionary = save.data.duplicate(true)
	var legacy: EncounterStats = VoyageDirector.encounter(save.data)
	check(legacy.enemy_roles == ["heavy","hunter"] and legacy.route == 2 and not legacy.linear_progression,"underway old battle preserves its fleet and route")
	check(save.load_game() and save.data.fleet == JSON.parse_string(JSON.stringify(before.fleet)) and save.data.gold == 1234 and save.data.salvage == 16,"v2 fleet names, upgrades and currency survive loading unchanged")
	save.begin_encounter()
	check(save.data.route == 2 and not save.data.has("progression"),"resume does not reroll legacy encounter")
	var old_reward: int = VoyageDirector.reward(save.data)
	save.settle(true,40,2)
	check(save.data.gold == 1234+old_reward and save.data.stop == 4,"legacy victory awards exact old reward and keeps progress")
	save.begin_encounter()
	check(save.data.progression == 1 and save.data.route == 0 and VoyageDirector.encounter(save.data).linear_progression,"next new battle adopts automatic path without save reset")
	save.settle(false,0,0)
	var identities: Dictionary = save.data.fleet.duplicate(true)
	var bounded: bool = true
	var deterministic: bool = true
	for chapter: int in range(1,1001):
		for stop: int in range(5):
			var state: Dictionary = CampaignSave.fresh("Test","Test",0,174)
			state.chapter = chapter
			state.stop = stop
			var info: EncounterStats = VoyageDirector.encounter(state)
			bounded = bounded and info.enemy_roles.size() <= 3 and info.difficulty <= 6
			state.route = 2
			deterministic = deterministic and VoyageDirector.encounter(state).enemy_roles == info.enemy_roles and VoyageDirector.encounter(state).layout == info.layout
	check(bounded and deterministic,"5000 stages have capped deterministic threats independent of route choice")
	data = CampaignSave.fresh("Test","Test",0,174)
	check(VoyageDirector.encounter(data).enemy_roles == ["raider"] and VoyageDirector.reward(data) == 80,"first duel remains approachable and pays starter upgrade gold")
	data.stop = 1
	check(VoyageDirector.encounter(data).enemy_roles == ["raider"],"second encounter still a solo raider")
	data.stop = 2
	check(VoyageDirector.encounter(data).enemy_roles == ["hunter"],"third encounter introduces hunter")
	data.stop = 3
	check(VoyageDirector.encounter(data).enemy_roles == ["heavy"],"fourth encounter introduces heavy")
	data.stop = 4
	check(VoyageDirector.encounter(data).boss_name == "The Tidewarden","fifth destination retains named special boss")
	var first_reward: int = VoyageDirector.reward(data)
	check(80+100+125+155+240-150 >= int(Shipyard.HULLS.brig.price)+150,"first chapter funds a brig and extra cannon even with a 150-gold repair budget")
	data.chapter = 3
	check(VoyageDirector.encounter(data).enemy_roles.size() == 2 and VoyageDirector.reward(data) > first_reward,"later bosses get escort and increased reward")
	data.setbacks = 2
	check(VoyageDirector.encounter(data).enemy_roles.size() == 1 and VoyageDirector.encounter(data).relief == 2,"repeat defeats remove escort and weaken retry without moving progress")
	data.gold = 0
	data.salvage = 0
	save.commit(data)
	save.begin_encounter()
	save.settle(false,0,0)
	check(save.data.health >= 60 and save.data.salvage >= 2 and save.data.stop == 4,"zero-gold defeat recovers seaworthy ship and tradeable salvage")
	check(Shipyard.purchase(save,"salvage","") and save.data.gold > 0,"stranded captain can earn upgrade money through confirmed salvage trade")
	var game: Node = preload("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	root.size = Vector2i(1280,720)
	game.campaign.save = save
	game.campaign.show_chart()
	await frames(5)
	var chart: Control = game.campaign.chart
	check(chart.size.y/game.panel.size.y > 0.65,"map uses over 65 percent of standard page height")
	var choices: int = 0
	var routes: bool = false
	for button: Node in game.panel.find_children("*","Button",true,false):
		if button.text.begins_with("Set Sail"): choices += 1
		routes = routes or "Trade Winds" in button.text or "Blackwater" in button.text or "Reef Passage" in button.text
	check(choices == 1 and not routes,"one Set Sail destination with no difficulty buttons")
	check("gold" in game.campaign.status.text and "Storm Regent" in game.campaign.status.text,"next destination displays real enemies and expected reward")
	check(absf(chart.point(0).y-chart.point(1).y) > chart.size.y*0.3,"route winds across height as well as width")
	game.campaign.start_travel()
	await frames(5)
	check(game.screen == "travel" and game.campaign.chart.travel > 0,"full-page chart preserves animated sailing")
	await tap(KEY_ESCAPE)
	check(game.screen == "battle" and game.campaign.in_battle,"Escape skips travel into actual next battle")
	var boss: BroadsideShip = game.arena.enemy
	check(boss.ability != null and boss.hull.max_health <= 160 and boss.guns.gun_count <= 2,"new progression still configures real capped boss abilities")
	game.show_menu()
	game.campaign.show_chart()
	var original_path: String = save.path
	save.path = "user://m2f_absent_folder/campaign.json"
	var stop_before: int = save.data.stop
	game.campaign.start_travel()
	check(game.screen == "chart" and game.campaign.status.text.contains("Cannot write") and save.data.stop == stop_before,"failed sailing save returns a readable error without advancing")
	save.path = original_path
	game.show_menu()
	game.audio.shutdown()
	OS.delay_msec(150)
	game.queue_free()
	await frames()
	for suffix: String in ["",".bak",".tmp"]: DirAccess.remove_absolute(save.path+suffix)
	print("M2F VOYAGE RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
