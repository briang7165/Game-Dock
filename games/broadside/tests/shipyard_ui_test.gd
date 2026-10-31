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
func run() -> void:
	var game: Node = preload("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	var save: CampaignSave = game.campaign.save
	save.path = "user://shipyard_ui_test.json"
	var data: Dictionary = CampaignSave.fresh("Tester","The Copper Finch",1,123)
	data.gold = 10000
	save.commit(data)
	Shipyard.purchase(save,"hull","brig")
	game.campaign.show_harbor()
	# Resize immediately while removed main/chart roots await queue_free.
	root.size = Vector2i(800,450)
	await frames()
	var harbor: ShipyardUI = game.panel
	check(harbor.get_node_or_null("modal") == null,"no modal overlay exists")
	check(harbor.upgrade_buttons.size() == 6,"firepower includes all six fittings")
	var descriptions: int = 0
	for control: Node in harbor.find_children("*","Control",true,false):
		if not control.tooltip_text.is_empty(): descriptions += 1
	check(descriptions == 0,"no duplicate native upgrade tooltips")
	var pick: Button = harbor.upgrade_buttons["upgrade:gunners"]
	pick.grab_focus()
	await frames()
	check(harbor.detail_title.text == "Faster Reloading" and harbor.detail_text.text.contains("faster"),"keyboard gets short plain-language explanation")
	var gold: int = save.data.gold
	var detail_parent: Node = harbor.detail.get_parent()
	await tap(KEY_SPACE)
	check(not harbor.offer.is_empty() and save.data.gold == gold and pick.has_focus(),"Space arms estimate without charging or jumping focus")
	check(harbor.detail.get_parent() == detail_parent,"selection never reparents detail panel")
	harbor.describe("weapon","chain")
	check(harbor.detail_title.text == "Faster Reloading","hover cannot replace a pending quote")
	await tap(KEY_ESCAPE)
	check(game.screen == "harbor" and harbor.offer.is_empty() and save.data.gold == gold,"Escape cancels in place")
	await tap(KEY_ENTER)
	harbor.confirm_button.grab_focus()
	await tap(KEY_ENTER)
	check(save.data.gold == gold-100 and Shipyard.rank(save.data,"gunners") == 1,"explicit keyboard confirmation charges once")
	harbor.confirm_offer()
	check(save.data.gold == gold-100,"duplicate confirmation cannot charge again")
	await click(harbor.upgrade_buttons["upgrade:cannons"])
	await click(harbor.confirm_button)
	check(Shipyard.guns_for(save.data).gun_count == 2,"mouse buys fitting through one checkout")
	harbor.selected = "brig"
	harbor.refresh()
	harbor.inspect("upgrade","gunners")
	await frames()
	await click(harbor.confirm_button)
	check(save.data.hull == "sloop" and save.data.fleet.brig.upgrades.get("gunners",0) == 1,"inactive ship purchase remains isolated")
	data = save.data.duplicate(true)
	data.health = 30
	save.commit(data)
	harbor.refresh()
	var repair_position: Vector2 = harbor.repair_bar.global_position
	gold = save.data.gold
	harbor.show_category("Defense & Repairs")
	harbor.scroll.scroll_vertical = 100
	await frames()
	check(harbor.repair_bar.global_position == repair_position and save.data.health == 30 and save.data.gold == gold,"repairs stay pinned without automatic spending")
	harbor.inspect("repair","","active")
	check(harbor.offer.selected == "sloop" and harbor.selected == "brig","pinned repair targets active ship even while inspecting brig")
	harbor.confirm_offer()
	check(save.data.health == 60 and save.data.gold == gold-15 and save.data.fleet.brig.health == 96,"repair charges active ship's exact missing HP only")
	harbor.show_category("Firepower")
	harbor.describe("weapon","carronade")
	check(harbor.detail_title.text == "Close-Range Cannons" and harbor.detail_text.text.contains("up close"),"carronades explained for a young player")
	harbor.show_page("Fleet")
	await frames()
	check(harbor.fleet_buttons.size() == 4,"all permanent fleet cards remain available")
	gold = save.data.gold
	for code: Key in [KEY_W,KEY_A,KEY_S,KEY_D,KEY_UP,KEY_DOWN,KEY_LEFT,KEY_RIGHT]: await tap(code)
	check(save.data.gold == gold and game.screen == "harbor","navigation does not spend or launch battle")
	await tap(KEY_ESCAPE)
	check(game.screen == "chart","Escape without pending estimate returns to chart")
	game.show_menu()
	game.audio.shutdown()
	OS.delay_msec(150)
	game.queue_free()
	await frames()
	for suffix: String in ["",".bak",".tmp"]: DirAccess.remove_absolute(save.path+suffix)
	print("SHIPYARD UI RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
