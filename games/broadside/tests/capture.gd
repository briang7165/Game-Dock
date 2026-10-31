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
			"fullscreen":
				game.display.set_fullscreen(true,false)
				await create_timer(0.6).timeout
			"menu": game.show_menu()
			"pause": game.pause_battle()
			"result": game.end_battle(true)
			"settings": game.pause_battle(); game.show_settings()
			"indicator": game.arena.enemy.position = Vector2(1050,700)
			"hud":
				game.arena.player.take_damage(game.arena.player.hull.max_health*0.8)
				game.arena.player.starboard.remaining = 0
				game.arena.enemy.position = Vector2(1050,700)
				await create_timer(0.6).timeout
		await process_frame
	await RenderingServer.frame_post_draw
	if args.size() > 0:
		var error: Error = root.get_texture().get_image().save_png(args[0])
		print("Capture result: ",error, " size: ",root.size)
	if args.size() > 1 and args[1] == "fullscreen":
		game.display.set_fullscreen(false,false)
	game.quit_game()
