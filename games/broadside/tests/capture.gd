extends SceneTree
## Optional real-render smoke/capture, never used to claim human playtesting.
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game: Node = preload("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_battle()
	await create_timer(1.0).timeout
	game.arena.player.fire_loaded()
	await create_timer(0.15).timeout
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 1:
		match args[1]:
			"menu": game.show_menu()
			"pause": game.pause_battle()
			"result": game.end_battle(true)
		await process_frame
	await RenderingServer.frame_post_draw
	if args.size() > 0:
		var error: Error = root.get_texture().get_image().save_png(args[0])
		print("Capture result: ",error, " size: ",root.size)
	quit()
