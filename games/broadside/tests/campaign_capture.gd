extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game: Node = preload("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	game.campaign.save.path = "user://capture_test.json"
	game.campaign.save.data = CampaignSave.fresh("Captain Rowan","The Wayfarer",0,1234)
	var args := OS.get_cmdline_user_args()
	var mode: String = args[1] if args.size() > 1 else "chart"
	if args.size() > 2 and args[2] == "fullscreen":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	if mode == "harbor":
		game.campaign.show_harbor()
	elif mode in ["fleet","boss"]:
		game.campaign.save.data.chapter = 3
		game.campaign.save.data.stop = 4 if mode == "boss" else 3
		game.campaign.save.data.fleet.frigate = FleetState.bare("frigate")
		FleetState.project(game.campaign.save.data,"frigate")
		game.campaign.save.data.health = 144
		game.campaign.show_chart()
		game.campaign.start_travel(2)
		game.campaign.enter_battle()
		game.arena.player.rotation = PI/2
	else:
		game.campaign.show_chart()
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	if args.size() > 0:
		print("Capture: ",root.get_texture().get_image().save_png(args[0])," size ",root.get_texture().get_size())
	for suffix: String in ["",".bak",".tmp"]: DirAccess.remove_absolute(game.campaign.save.path+suffix)
	game.quit_game()
