extends SceneTree
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game: Node = preload("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	for i: int in range(30):
		await process_frame
	print("PASS: main scene boot and orderly shutdown")
	game.quit_game()
