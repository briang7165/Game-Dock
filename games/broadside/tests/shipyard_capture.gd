extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game: Node = preload("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	var save: CampaignSave = game.campaign.save
	save.path = "user://shipyard_capture.json"
	var data: Dictionary = CampaignSave.fresh("Rowan Ashford","The Wayfarer",0,123)
	data.gold = 3750
	data.salvage = 24
	data.wins = 8
	save.commit(data)
	Shipyard.purchase(save,"hull","brig")
	Shipyard.rename_ship(save,"brig","The Brass Finch")
	Shipyard.purchase(save,"upgrade","rudder")
	Shipyard.purchase(save,"upgrade","rudder")
	Shipyard.purchase(save,"upgrade","sails")
	Shipyard.purchase(save,"upgrade","cannons")
	data = save.data.duplicate(true)
	data.health = 34
	save.commit(data)
	game.campaign.show_harbor()
	var args := OS.get_cmdline_user_args()
	var mode: String = args[1] if args.size() > 1 else "fleet"
	if args.size() > 2 and args[2] == "fullscreen": DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	var harbor: ShipyardUI = game.panel
	await create_timer(0.5).timeout
	if mode == "compare":
		harbor.show_page("Fleet")
		harbor.show_ship("brig")
		await process_frame
		harbor.scroll.scroll_vertical = 300
	if mode == "upgrade":
		harbor.category = "Firepower"
		harbor.refresh()
		await process_frame
		harbor.inspect("weapon","carronade")
	if mode == "repair": harbor.inspect("repair","","active")
	if mode == "chart": game.campaign.show_chart()
	if mode == "menu": game.show_menu()
	await create_timer(0.5).timeout
	if mode in ["upgrade","repair","compare","fleet"]:
		var fixed: Rect2 = harbor.repair_bar.get_global_rect()
		var stock_rect: Rect2 = harbor.scroll.get_global_rect()
		var actions: Rect2 = harbor.confirm_button.get_global_rect()
		var footer: Rect2 = harbor.price_text.get_global_rect()
		assert(fixed.end.y < stock_rect.position.y,"repairs stay above inventory")
		assert(not footer.intersects(actions),"price and confirmation do not overlap")
		assert(harbor.get_global_rect().encloses(actions),"confirmation fits window")
		print("PASS: pinned repairs and unclipped checkout at ",root.size)
	await RenderingServer.frame_post_draw
	if args.size() > 0:
		var screenshot: Image = root.get_texture().get_image()
		print("Capture: ",screenshot.save_png(args[0])," size ",screenshot.get_size())
	for suffix: String in ["",".bak",".tmp"]: DirAccess.remove_absolute(save.path+suffix)
	game.quit_game()
