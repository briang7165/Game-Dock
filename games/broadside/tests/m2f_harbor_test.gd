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
	save.path = "user://m2f_harbor_test.json"
	var data: Dictionary = CampaignSave.fresh("Test","Copper Finch",0,123)
	data.gold = 10000
	data.salvage = 16
	save.commit(data)
	Shipyard.purchase(save,"hull","brig")
	game.campaign.show_harbor()
	await frames()
	var harbor: ShipyardUI = game.panel
	var gold: int = save.data.gold
	for pair: Array in [["long","Fleet"],["carronade","Crew"]]:
		harbor.show_page("Upgrades")
		await frames()
		await click(harbor.upgrade_buttons["weapon:"+pair[0]])
		check(not harbor.offer.is_empty(),"mouse selects "+pair[0]+" without payment")
		await click(harbor.navigation_buttons[pair[1]])
		check(harbor.page_name == pair[1] and harbor.offer.is_empty() and save.data.gold == gold,"pending estimate → "+pair[1]+" works immediately without spending")
	harbor.show_page("Upgrades")
	await frames()
	await click(harbor.upgrade_buttons["weapon:long"])
	harbor.category_buttons["Sailing & Handling"].grab_focus()
	await tap(KEY_ENTER)
	check(harbor.category == "Sailing & Handling" and harbor.offer.is_empty() and save.data.gold == gold,"keyboard category navigation cancels unpaid estimate")
	check("○○○" in harbor.upgrade_buttons["upgrade:sails"].text and "90 gold" in harbor.upgrade_buttons["upgrade:sails"].text,"card shows exact next price and empty pips")
	harbor.inspect("upgrade","sails")
	harbor.select_ship("brig")
	check(harbor.offer.is_empty() and harbor.selected == "brig","switching inspected vessel cancels quote")
	harbor.select_ship("sloop")
	harbor.show_category("Firepower")
	Shipyard.purchase(save,"upgrade","cannons")
	harbor.refresh()
	check("MAXED" in harbor.upgrade_buttons["upgrade:cannons"].text and "●" in harbor.upgrade_buttons["upgrade:cannons"].text,"completed upgrade shows MAXED and filled pips")
	harbor.inspect("upgrade","cannons")
	harbor.navigation_buttons.Fleet.grab_focus()
	await tap(KEY_SPACE)
	check(harbor.page_name == "Fleet" and harbor.offer.is_empty(),"keyboard can leave a maxed estimate")
	check(harbor.currency.text == "GOLD  %d" % int(save.data.gold) and harbor.salvage_label.text == "16 salvage","pinned currency matches saved balance")
	check(ShipyardUI.remaining_levels(FleetState.view(save.data,"galleon")) > ShipyardUI.remaining_levels(FleetState.view(save.data,"sloop")),"larger ships retain greater upgrade potential")
	harbor.selected = "galleon" # Inspecting an unowned ship must not grant it through a sale.
	harbor.inspect("salvage","")
	gold = save.data.gold
	check(save.data.gold == gold and save.data.salvage == 16,"salvage inspection never sells")
	harbor.confirm_offer()
	harbor.confirm_offer()
	check(not save.data.fleet.has("galleon") and save.data.salvage == 0 and save.data.gold == gold+192 and harbor.currency.text == "GOLD  %d" % int(save.data.gold),"salvage confirmation sells once and refreshes gold")
	harbor.show_page("Upgrades")
	harbor.inspect("weapon","long")
	gold = save.data.gold
	await click(harbor.navigation_buttons["Voyage chart"])
	check(game.screen == "chart" and save.data.gold == gold,"unpaid estimate → voyage chart leaves without purchase")
	game.show_menu()
	game.audio.shutdown()
	OS.delay_msec(150)
	game.queue_free()
	await frames()
	for suffix: String in ["",".bak",".tmp"]: DirAccess.remove_absolute(save.path+suffix)
	print("M2F HARBOR RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
