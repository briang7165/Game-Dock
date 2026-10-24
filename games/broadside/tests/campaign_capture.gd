extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game: Node = preload("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	game.campaign.save.data = CampaignSave.fresh("Captain Rowan","The Wayfarer",0,1234)
	game.campaign.show_chart()
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		print("Capture: ",root.get_texture().get_image().save_png(args[0]))
	game.quit_game()
