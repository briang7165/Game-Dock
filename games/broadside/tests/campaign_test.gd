extends SceneTree
var failures: int = 0
var checks: int = 0
var game: Node

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print("PASS: " if ok else "FAIL: ",description)

func frames(count: int) -> void:
	for i: int in range(count):
		await physics_frame
		await process_frame

func run() -> void:
	var save := CampaignSave.new()
	save.path = "user://campaign_test.json"
	check(save.commit(CampaignSave.fresh("  Élodie\n","  ",2,1234)),"create versioned campaign save")
	check(save.data.captain == "Élodie" and save.data.ship == "The Wayfarer","names trim controls and use blank defaults")
	check(save.begin_encounter() and save.settle(true,20),"encounter begins and settles once")
	check(not save.settle(true,20) and save.data.stop == 1,"duplicate result cannot advance voyage twice")
	var restored := CampaignSave.new()
	restored.path = save.path
	check(restored.load_game() and restored.data.captain == "Élodie" and restored.data.stop == 1,"identity and voyage survive reload")
	var broken := FileAccess.open(save.path,FileAccess.WRITE)
	broken.store_string("corrupt")
	broken.close()
	check(restored.load_game() and not restored.error.is_empty(),"corrupt primary recovers valid backup")
	var invalid: Dictionary = restored.data.duplicate(true)
	invalid.version = 999
	check(not restored.commit(invalid),"future unsupported version cannot overwrite save")
	check(save.commit(CampaignSave.fresh("Captain Test","The Lantern",1,42)),"restore clean deterministic test voyage")
	for i: int in range(12):
		save.begin_encounter()
		save.settle(true,40)
	check(save.data.chapter == 3 and save.data.stop == 2 and save.data.bosses == 2,"five-stop chapters continue beyond first and second boss")
	var stop: int = int(save.data.stop)
	save.begin_encounter()
	save.settle(false,0)
	check(save.data.stop == stop and save.data.health > 0 and save.data.captain == "Captain Test","defeat preserves voyage/identity and provides viable recovery")
	game = preload("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	game.campaign.save = save
	game.campaign.show_identity(true)
	await frames(2)
	check(root.gui_get_focus_owner() == game.campaign.captain_edit,"identity opens with text focus")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_W
	key.unicode = 119
	key.pressed = true
	Input.parse_input_event(key)
	await frames(2)
	check(root.gui_get_focus_owner() == game.campaign.captain_edit and "w" in game.campaign.captain_edit.text,"W types in name instead of navigating")
	key = key.duplicate()
	key.pressed = false
	Input.parse_input_event(key)
	game.campaign.show_chart()
	game.campaign.start_travel()
	await frames(30)
	check(game.screen == "travel" and game.campaign.chart.travel > 0,"chart animates sailing between battles")
	game.campaign.enter_battle()
	await frames(2)
	check(game.screen == "battle" and game.campaign.in_battle and game.arena.player.health == 60,"skip enters real fragile-sloop combat")
	game.arena.enemy.take_damage(1000)
	await frames(60)
	check(game.screen == "campaign_result" and save.data.stop == stop+1,"real enemy sinking saves campaign result")
	game.campaign.show_harbor()
	game.campaign.show_chart()
	game.campaign.start_travel()
	await frames(250)
	check(game.screen == "battle","sailing auto-completes without requiring skip")
	game.arena.player.take_damage(1000)
	await frames(60)
	check(game.screen == "campaign_result" and save.data.health > 0,"real defeat returns to safe recovery")
	game.audio.shutdown()
	OS.delay_msec(150)
	await frames(3)
	game.queue_free()
	await frames(3)
	for suffix: String in ["",".bak",".tmp"]:
		DirAccess.remove_absolute(save.path+suffix)
	print("CAMPAIGN RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
