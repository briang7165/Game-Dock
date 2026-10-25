extends SceneTree
var checks: int = 0
var failures: int = 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("PASS: " if ok else "FAIL: ",description)
func run() -> void:
	var save := CampaignSave.new()
	save.path = "user://fleet_test.json"
	for suffix: String in ["",".bak",".tmp",".v1.bak"]: DirAccess.remove_absolute(save.path+suffix)
	var legacy: Dictionary = CampaignSave.fresh("Old Captain","Old Faithful",2,123)
	legacy.version = 1
	legacy.erase("fleet")
	legacy.erase("revision")
	legacy.hull = "frigate"
	legacy.upgrades = {"cannons":2,"sails":3,"armor":3,"cargo":2}
	legacy.weapon = "long"
	legacy.gold = 18000
	legacy.salvage = 17
	legacy.chapter = 12
	legacy.stop = 3
	legacy.health = 72
	var file := FileAccess.open(save.path,FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy,"\t"))
	file.close()
	var original: PackedByteArray = FileAccess.get_file_as_bytes(save.path)
	check(save.load_game(),"v1 migration completes")
	print(save.error)
	if save.data.is_empty(): quit(1); return
	check(FileAccess.get_file_as_bytes(save.path+".v1.bak") == original,"legacy bytes archived exactly before migration")
	check(save.data.gold == 18000 and save.data.salvage == 17 and save.data.chapter == 12 and save.data.stop == 3,"migration preserves currencies and voyage")
	check(JSON.parse_string(JSON.stringify(save.data.fleet.frigate.upgrades)) == JSON.parse_string(JSON.stringify(legacy.upgrades)) and save.data.health == 72 and save.data.weapon == "long" and save.data.ship == "Old Faithful","legacy purchases, over-cap tiers, condition and identity retained")
	check(save.data.fleet.has("sloop") and save.data.fleet.size() == 2,"legacy active vessel and original starter are owned")
	check(not Shipyard.purchase(save,"upgrade","sails"),"grandfathered tiers retained without allowing further over-cap purchase")
	check(Shipyard.activate(save,"sloop") and save.data.upgrades.is_empty() and save.data.weapon == "standard","switch restores independent starter loadout")
	check(Shipyard.purchase(save,"upgrade","rudder") and Shipyard.purchase(save,"upgrade","sails"),"starter accepts mobility upgrades")
	check(Shipyard.purchase(save,"hull","brig") and save.data.hull == "sloop" and save.data.fleet.sloop.upgrades.rudder == 1,"larger ship purchase retains upgraded active sloop")
	check(Shipyard.purchase(save,"upgrade","armor","brig") and save.data.hull == "sloop" and save.data.fleet.brig.upgrades.armor == 1 and not save.data.upgrades.has("armor"),"inactive ship upgrade is isolated")
	var offer: Dictionary = Shipyard.quote(save.data,"upgrade","cannons","brig")
	var gold: int = save.data.gold
	check(Shipyard.confirm(save,offer) and save.data.gold == gold-150,"confirmation charges once")
	check(not Shipyard.confirm(save,offer) and save.data.gold == gold-150,"repeated confirmation is rejected without charge")
	check(not Shipyard.purchase(save,"upgrade","cannons","brig"),"brig cannon tier cap enforced")
	check(Shipyard.purchase(save,"upgrade","cargo","sloop") and not Shipyard.purchase(save,"upgrade","lookout","sloop"),"sloop utility capacity enforced")
	check(Shipyard.rename_ship(save,"brig","The Brass Finch") and save.data.hull == "sloop" and save.data.fleet.brig.ship == "The Brass Finch","inactive ship can be named")
	check(Shipyard.activate(save,"brig") and save.data.ship == "The Brass Finch" and save.data.health == 114 and Shipyard.guns_for(save.data).gun_count == 3,"switch restores brig name, hull and three guns")
	check(Shipyard.purchase(save,"weapon","chain"),"owned ship buys and equips chain shot")
	gold = save.data.gold
	check(Shipyard.purchase(save,"weapon","standard") and Shipyard.purchase(save,"weapon","chain") and save.data.gold == gold,"previously purchased weapon re-equips without repeat charge")
	var restored := CampaignSave.new()
	restored.path = save.path
	restored.load_game()
	check(restored.load_game() and JSON.parse_string(JSON.stringify(restored.data.fleet)) == JSON.parse_string(JSON.stringify(save.data.fleet)),"entire fleet survives reopening")
	var ship := BroadsideShip.new()
	root.add_child(ship)
	Shipyard.apply(ship,save.data)
	check(ship.ship_class == "brig" and ship.guns.gun_count == 3 and ship.guns.damage == 10 and ship.hull.max_health == 114,"fleet data reaches real ship renderer and combat loadout")
	ship.queue_free()
	check(save.begin_encounter() and not Shipyard.activate(save,"sloop") and not Shipyard.purchase(save,"upgrade","gunners","sloop"),"saved encounter locks entire fleet")
	check(save.settle(false,0) and save.data.fleet.brig.health == save.data.health,"rescue condition written back only to active vessel")
	check(FileAccess.get_file_as_bytes(save.path+".v1.bak") == original,"later saves never overwrite legacy archive")
	var snapshot: Dictionary = save.data.duplicate(true)
	var future: Dictionary = snapshot.duplicate(true)
	future.version = 99
	file = FileAccess.open(save.path,FileAccess.WRITE)
	file.store_string(JSON.stringify(future))
	file.close()
	check(not restored.load_game() and JSON.parse_string(FileAccess.get_file_as_string(save.path)).version == 99,"future-version save cannot be rolled back over a valid old backup")
	# A deliberately different legacy archive must never be replaced.
	file = FileAccess.open(save.path,FileAccess.WRITE)
	legacy.gold = 999
	file.store_string(JSON.stringify(legacy))
	file.close()
	check(not restored.load_game() and FileAccess.get_file_as_bytes(save.path+".v1.bak") == original,"conflicting legacy archive blocks migration without destroying either file")
	for suffix: String in ["",".bak",".tmp",".v1.bak"]: DirAccess.remove_absolute(save.path+suffix)
	legacy.hull = "sloop"
	legacy.upgrades = {}
	for key_name: String in ["weapon","salvage","crew","journal","owned_weapons","ships_sunk","gold_earned"]: legacy.erase(key_name)
	file = FileAccess.open(save.path,FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	check(restored.load_game() and restored.data.weapon == "standard" and restored.data.fleet.sloop.owned_weapons == ["standard"],"early M2-A save migrates with missing optional equipment fields")
	# Simulate inability to create the legacy archive by placing a directory at its filename.
	for suffix: String in ["",".bak",".tmp",".v1.bak"]: DirAccess.remove_absolute(save.path+suffix)
	file = FileAccess.open(save.path,FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	var bytes_before: PackedByteArray = FileAccess.get_file_as_bytes(save.path)
	DirAccess.make_dir_absolute(save.path+".v1.bak")
	check(not restored.load_game() and FileAccess.get_file_as_bytes(save.path) == bytes_before,"backup failure leaves original save unchanged")
	DirAccess.remove_absolute(save.path+".v1.bak")
	await process_frame
	for suffix: String in ["",".bak",".tmp",".v1.bak"]: DirAccess.remove_absolute(save.path+suffix)
	print("FLEET RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
