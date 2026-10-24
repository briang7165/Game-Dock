extends SceneTree
var checks: int = 0
var failures: int = 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("PASS: " if ok else "FAIL: ",description)
func run() -> void:
	var save := CampaignSave.new()
	save.path = "user://shipyard_test.json"
	save.commit(CampaignSave.fresh("Test","Test",0,42))
	check(Shipyard.hull_for(save.data).max_health == 60 and Shipyard.guns_for(save.data).gun_count == 1 and Shipyard.guns_for(save.data).damage == 16,"starter stays fragile with one gun per side")
	check(not Shipyard.purchase(save,"hull","brig") and save.data.gold == 0,"unaffordable ship cannot charge or change hull")
	save.begin_encounter()
	save.settle(true,20)
	check(save.data.gold == 80 and save.data.salvage == 2 and save.data.health == 20,"victory pays once and retains damage")
	check(not save.settle(true,20) and save.data.gold == 80,"duplicate result cannot farm gold")
	check(Shipyard.purchase(save,"repair","") and save.data.gold == 60 and save.data.health == 60,"repair charges exact cost and restores hull")
	var next: Dictionary = save.data.duplicate(true)
	next.gold = 20000
	save.commit(next)
	var estimate: Dictionary = Shipyard.preview(save.data,"hull","brig")
	check(estimate.hull == "brig" and save.data.hull == "sloop" and save.data.gold == 20000,"purchase preview is non-mutating")
	for id: String in ["brig","frigate","galleon"]:
		check(Shipyard.purchase(save,"hull",id) and Shipyard.guns_for(save.data).gun_count == int(Shipyard.HULLS[id].guns),"purchase distinct hull and starting guns: "+id)
	check(Shipyard.purchase(save,"upgrade","cannons") and Shipyard.purchase(save,"upgrade","cannons") and not Shipyard.purchase(save,"upgrade","cannons"),"gun upgrades stop at capacity and rank limit")
	for id: String in Shipyard.UPGRADES:
		if id != "cannons": check(Shipyard.purchase(save,"upgrade",id),"upgrade persists: "+id)
	var upgraded: HullStats = Shipyard.hull_for(save.data)
	check(upgraded.max_health == 226 and upgraded.top_speed > 125 and upgraded.turn_rate > 0.46,"sails/rudder and plating apply actual stat tradeoffs")
	check(Shipyard.purchase(save,"weapon","long") and Shipyard.guns_for(save.data).projectile_lifetime > 2.9,"long gun purchase changes range")
	check(Shipyard.purchase(save,"weapon","carronade") and Shipyard.guns_for(save.data).damage == 23 and Shipyard.guns_for(save.data).projectile_lifetime < 2.9,"carronades exchange range for damage")
	var reloaded := CampaignSave.new()
	reloaded.path = save.path
	check(reloaded.load_game() and reloaded.data.hull == save.data.hull and reloaded.data.weapon == save.data.weapon and int(reloaded.data.gold) == int(save.data.gold) and Shipyard.rank(reloaded.data,"cannons") == 2,"purchases and economy survive disk reload")
	check(save.begin_encounter() and not Shipyard.purchase(save,"upgrade","sails"),"cannot alter loadout during saved encounter")
	save.settle(false,0)
	next = save.data.duplicate(true)
	next.gold = 0
	save.commit(next)
	save.begin_encounter()
	save.settle(false,0)
	check(save.data.health >= 60 and save.data.gold == 0 and save.data.hull == "galleon","bankrupt defeat cannot strand player or remove ship")
	next = save.data.duplicate(true)
	next.upgrades["cannons"] = 999
	check(not save.commit(next),"invalid saved upgrade ranks rejected")
	var game: Node = preload("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	game.campaign.save = save
	game.campaign.show_chart()
	game.campaign.start_travel()
	game.campaign.enter_battle()
	await process_frame
	check(game.arena.player.guns.gun_count == 6 and game.arena.player.ship_class == "galleon" and game.arena.player.hull_shape.shape.radius > 20,"purchased loadout, silhouette and collider reach real battle")
	check(game.arena.player.fire_loaded() == 12,"six upgraded cannons fire from each side")
	game.show_menu()
	await process_frame
	game.audio.shutdown()
	OS.delay_msec(150)
	game.queue_free()
	await process_frame
	for suffix: String in ["",".bak",".tmp"]: DirAccess.remove_absolute(save.path+suffix)
	print("SHIPYARD RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
