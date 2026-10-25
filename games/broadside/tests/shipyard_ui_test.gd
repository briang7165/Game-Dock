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
	await frames()
	var harbor: ShipyardUI = game.panel
	check(harbor.fleet_buttons.size() == 4,"gallery includes all four hull classes")
	check(harbor.find_children("*","ShipPortrait",true,false).size() == 6,"active portrait, selected portrait and four cards reuse battle renderer")
	check(harbor.upgrade_buttons.size() == 6,"firepower contains two upgrades and four loadouts")
	check(harbor.find_children("*","UpgradeIcon",true,false).size() == 6,"every displayed fitting has an original icon")
	var pick: Button = harbor.upgrade_buttons["upgrade:gunners"]
	pick.grab_focus()
	await frames()
	check(harbor.detail_title.text.contains("Gunnery") and harbor.detail_text.text.contains("Reload") and harbor.detail_text.text.contains("100 gold"),"keyboard focus exposes numerical effects and price")
	var gold: int = save.data.gold
	await tap(KEY_SPACE)
	check(not harbor.offer.is_empty() and save.data.gold == gold and root.gui_get_focus_owner() == harbor.cancel_button,"Space selects estimate without spending; Cancel focused")
	await tap(KEY_ESCAPE)
	check(game.screen == "harbor" and harbor.offer.is_empty() and save.data.gold == gold,"Escape cancels estimate without leaving harbor")
	pick = harbor.upgrade_buttons["upgrade:gunners"]
	pick.grab_focus()
	await frames()
	await tap(KEY_ENTER)
	await tap(KEY_D)
	check(root.gui_get_focus_owner() == harbor.confirm_button,"D navigates to explicit confirmation")
	await tap(KEY_ENTER)
	check(save.data.gold == gold-100 and Shipyard.rank(save.data,"gunners") == 1,"keyboard confirmation persists exactly one purchase")
	check(game.screen == "harbor" and not save.data.active,"shipyard keys never launch battle")
	# Real GUI hit tests at the displayed button position, not signal emission.
	pick = harbor.upgrade_buttons["upgrade:cannons"]
	pick.grab_focus()
	await frames(5)
	await click(pick)
	check(not harbor.offer.is_empty() and harbor.detail_text.text.contains("Guns / side 1 → 2"),"mouse selection opens correct cannon estimate")
	await click(harbor.confirm_button)
	check(Shipyard.guns_for(save.data).gun_count == 2 and save.data.gold == gold-250,"mouse confirms cannon purchase once")
	harbor.select_ship("brig")
	await frames()
	check(save.data.hull == "sloop" and harbor.selected == "brig","inspection leaves active ship unchanged")
	harbor.inspect("upgrade","gunners")
	await frames()
	await click(harbor.confirm_button)
	check(save.data.fleet.brig.upgrades.get("gunners",0) == 1 and save.data.hull == "sloop","GUI purchases upgrade for inactive brig")
	harbor.category = "Utility & Economy"
	harbor.refresh()
	await frames()
	check(harbor.upgrade_buttons.size() == 2 and harbor.upgrade_buttons.has("upgrade:cargo"),"category switching filters working upgrades")
	harbor.inspect("upgrade","cargo")
	await frames()
	check(harbor.detail_text.text.contains("Bonus prize gold 0% → 20%") and harbor.detail_text.text.contains("Extra salvage 0 → 1"),"economy estimate shows actual reward changes")
	await tap(KEY_ESCAPE)
	# All directions are bound for keyboard navigation; traversing cannot spend.
	gold = save.data.gold
	for code: Key in [KEY_W,KEY_A,KEY_S,KEY_D,KEY_UP,KEY_DOWN,KEY_LEFT,KEY_RIGHT]: await tap(code)
	check(save.data.gold == gold and game.screen == "harbor","all movement navigation keys preserve money and encounter state")
	harbor.last_crew_button.grab_focus()
	await frames(5)
	check(harbor.scroll.scroll_vertical > 0,"keyboard focus reveals lower controls through scrolling")
	await tap(KEY_ESCAPE)
	check(game.screen == "chart","Escape outside estimate returns to voyage chart")
	game.show_menu()
	game.audio.shutdown()
	OS.delay_msec(150)
	game.queue_free()
	await frames()
	for suffix: String in ["",".bak",".tmp"]: DirAccess.remove_absolute(save.path+suffix)
	print("SHIPYARD UI RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
