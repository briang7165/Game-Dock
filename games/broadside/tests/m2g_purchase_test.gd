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
	var game: Node = preload("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	root.size = Vector2i(1280,720)
	var save: CampaignSave = game.campaign.save
	save.path = "user://m2g_purchase_test.json"
	for sample: Array in [["brig",320],["brig",488],["frigate",800],["galleon",1500]]:
		var data: Dictionary = CampaignSave.fresh("Saved Captain","Saved Sloop",2,123)
		data.gold = sample[1]
		data.salvage = 9
		data.upgrades = {"sails":2,"cargo":1}
		check(save.commit(data),"purchase fixture saved")
		game.campaign.show_harbor()
		await frames()
		var harbor: ShipyardUI = game.panel
		await click(harbor.navigation_buttons.Fleet)
		await click(harbor.fleet_buttons[sample[0]])
		check(not harbor.offer.is_empty() and not harbor.confirm_button.disabled and save.data.gold == sample[1],"%s at %d gold: card opens visible payable estimate without charging" % sample)
		await click(harbor.confirm_button)
		check(save.data.fleet.has(sample[0]) and save.data.gold == sample[1]-int(Shipyard.HULLS[sample[0]].price),"%s purchase charges exact price and owns hull" % sample[0])
		check(save.data.fleet.sloop.upgrades.sails == 2 and save.data.captain == "Saved Captain" and save.data.ship == "Saved Sloop" and save.data.salvage == 9,"ship purchase preserves original fleet and identity")
		var gold: int = save.data.gold
		harbor.confirm_offer()
		check(save.data.gold == gold and "Purchase complete" in harbor.status.text,"repeat Confirm cannot charge and success is visible")
		harbor.show_ship(sample[0])
		await frames()
		check(harbor.confirm_button.text == "Make Active" and not harbor.confirm_button.disabled,"owned hull exposes pinned Make Active")
		await click(harbor.confirm_button)
		check(save.data.hull == sample[0] and save.data.fleet.sloop.upgrades.sails == 2,"real Make Active click preserves other ship")
		var reopened := CampaignSave.new()
		reopened.path = save.path
		check(reopened.load_game() and JSON.parse_string(JSON.stringify(reopened.data.fleet)) == JSON.parse_string(JSON.stringify(save.data.fleet)),"new fleet persists on disk")
	var all_data: Dictionary = CampaignSave.fresh("All Fittings","No Slots",0,123)
	all_data.gold = 100000
	save.commit(all_data)
	var bought_all: bool = true
	for hull_id: String in Shipyard.HULLS:
		if hull_id != "sloop": bought_all = Shipyard.purchase(save,"hull",hull_id) and bought_all
		for id: String in Shipyard.UPGRADES:
			var state: Dictionary = FleetState.view(save.data,hull_id)
			for level: int in range(Shipyard.tier_limit(state,id)):
				bought_all = Shipyard.purchase(save,"upgrade",id,hull_id) and bought_all
		for weapon: String in ["chain","long","carronade","standard"]:
			bought_all = Shipyard.purchase(save,"weapon",weapon,hull_id) and bought_all
		check(ShipyardUI.remaining_levels(FleetState.view(save.data,hull_id)) == 0,hull_id+" reaches every offered tier without slot blockers")
	check(bought_all,"all compatible tiers and weapons purchased across four permanent ships")
	var poor: Dictionary = CampaignSave.fresh("Poor","Reason",0,123)
	poor.gold = 488
	save.commit(poor)
	game.campaign.show_harbor()
	await frames()
	var harbor: ShipyardUI = game.panel
	await click(harbor.navigation_buttons.Fleet)
	await click(harbor.fleet_buttons.frigate)
	check("Need 312 more gold" in harbor.price_text.text and "Need 312 more gold" in harbor.status.text and harbor.confirm_button.disabled,"unaffordable selected hull gives exact shortfall in the same panel")
	check(not Shipyard.confirm(save,harbor.offer) and "Need 312 more gold" in save.error,"transaction uses same precise reason")
	await click(harbor.navigation_buttons.Upgrades)
	check(harbor.offer.is_empty(),"blocked quote cancels when navigating")
	var active: Dictionary = save.data.duplicate(true)
	active.active = true
	save.commit(active)
	harbor.show_page("Fleet")
	await frames()
	await click(harbor.fleet_buttons.brig)
	check("Finish your current battle" in harbor.status.text,"affordable hull blocked by saved battle explains resume route")
	check(not Shipyard.confirm(save,harbor.offer) and not save.data.fleet.has("brig"),"active battle cannot spend or grant hull")
	await click(harbor.navigation_buttons["Voyage chart"])
	check(game.screen == "chart" and save.data.active,"active save has safe route back to Resume")
	game.show_menu()
	game.audio.shutdown()
	OS.delay_msec(150)
	game.queue_free()
	await frames()
	for suffix: String in ["",".bak",".tmp"]: DirAccess.remove_absolute(save.path+suffix)
	print("M2G PURCHASE RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
