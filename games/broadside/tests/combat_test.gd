extends SceneTree
## Real scene/physics/input integration, without third-party test dependencies.
var failures: int = 0
var checks: int = 0
var game: Node

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + message)
	else:
		print("PASS: " + message)

func frames(count: int) -> void:
	for i: int in range(count):
		await physics_frame
		await process_frame

func key(code: Key, down: bool = true, echo: bool = false) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = down
	event.echo = echo
	Input.parse_input_event(event)

func tap(code: Key) -> void:
	key(code)
	await frames(1)
	key(code, false)
	await frames(1)

func run() -> void:
	game = preload("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await frames(2)
	check(root.gui_get_focus_owner() is Button, "main menu has keyboard focus")
	await tap(KEY_D)
	check(root.gui_get_focus_owner().text == "Settings", "D moves menu focus")
	await tap(KEY_UP)
	check(root.gui_get_focus_owner().text == "Set sail", "arrows move menu focus")
	await tap(KEY_ENTER)
	check(game.screen == "battle", "Enter starts real arena")
	var player: BroadsideShip = game.arena.player
	var enemy: BroadsideShip = game.arena.enemy
	enemy.set_physics_process(false)
	player.position = Vector2(-700,400)
	enemy.position = Vector2(700,400)
	await frames(2)
	var start: Vector2 = player.position
	key(KEY_W)
	await frames(30)
	key(KEY_W,false)
	check(player.position.y < start.y - 5, "W accelerates forward")
	player.speed = 0
	start = player.position
	key(KEY_UP)
	await frames(30)
	key(KEY_UP,false)
	check(player.position.y < start.y - 5, "Up accelerates forward")
	var heading: float = player.rotation
	key(KEY_A)
	await frames(15)
	key(KEY_A,false)
	check(player.rotation < heading, "A turns port")
	heading = player.rotation
	key(KEY_RIGHT)
	await frames(45) # Allow the deliberately heavy rudder to reverse its turn.
	key(KEY_RIGHT,false)
	check(player.rotation > heading, "Right turns starboard")
	player.speed = 0
	key(KEY_S)
	await frames(20)
	key(KEY_S,false)
	check(player.speed < 0, "S brakes into light reverse")
	player.speed = 0
	key(KEY_DOWN)
	await frames(20)
	key(KEY_DOWN,false)
	check(player.speed < 0, "Down brakes into light reverse")
	player.speed = 0
	player.rotation = 0
	player.set_physics_process(false)
	var hp: float = player.health
	await tap(KEY_Q)
	await tap(KEY_E)
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(1200,20)
	Input.parse_input_event(motion)
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.pressed = true
	Input.parse_input_event(mouse)
	await frames(1)
	mouse = mouse.duplicate()
	mouse.pressed = false
	Input.parse_input_event(mouse)
	check(get_nodes_in_group("projectiles").is_empty(), "Q, E and mouse click cannot fire")
	player.port.remaining = 1.0
	await tap(KEY_SPACE)
	check(get_nodes_in_group("projectiles").size() == 1, "Space fires only loaded starboard")
	check(is_equal_approx(player.port.remaining,1.0), "reloading port not consumed or reset")
	check(player.health == hp, "Space never repairs")
	for shot: Node in get_nodes_in_group("projectiles"):
		check(shot.direction.x > 0.99, "fixed outward starboard trajectory")
		shot.queue_free()
	await frames(1)
	player.port.remaining = 0
	player.starboard.remaining = 0
	key(KEY_SPACE)
	await frames(1)
	check(get_nodes_in_group("projectiles").size() == 2, "fresh Space fires both loaded batteries")
	for shot: Node in get_nodes_in_group("projectiles"):
		shot.queue_free()
	player.port.remaining = 0
	player.starboard.remaining = 0
	key(KEY_SPACE,true,true)
	await frames(1)
	check(get_nodes_in_group("projectiles").is_empty(), "OS key repeat cannot fire")
	player.set_physics_process(true)
	await frames(5)
	check(get_nodes_in_group("projectiles").is_empty(), "holding Space never refires")
	key(KEY_SPACE,false)
	player.port.remaining = 0.08
	player.starboard.remaining = 0.3
	await frames(8)
	check(player.port.ready() and not player.starboard.ready(), "independent automatic reload")
	await frames(16)
	check(player.starboard.ready(), "other side automatically reloads")
	player.fire_loaded()
	player.speed = 50
	enemy.set_physics_process(true)
	await tap(KEY_ESCAPE)
	check(paused and game.screen == "pause", "Escape pauses battle")
	start = player.position
	var enemy_start: Vector2 = enemy.position
	var remaining: float = player.port.remaining
	var shots: Array[Node] = get_nodes_in_group("projectiles")
	var shot_position: Vector2 = shots[0].position
	await frames(10)
	check(player.position == start and enemy.position == enemy_start, "pause freezes both hulls and AI")
	check(player.port.remaining == remaining and shots[0].position == shot_position, "pause freezes reload and shots")
	check(root.gui_get_focus_owner().text == "Resume", "pause keyboard focus")
	await tap(KEY_SPACE)
	check(not paused and game.screen == "battle", "Space activates Resume")
	check(player.port.remaining > 2.0, "menu Space does not leak to combat")
	enemy.set_physics_process(false)
	player.set_physics_process(false)
	for shot: Node in get_nodes_in_group("projectiles"):
		shot.queue_free()
	await frames(2)
	# Place stationary ships across clear water; real swept shots must hit target.
	player.position = Vector2(-650,550)
	enemy.position = Vector2(-450,550)
	player.rotation = 0
	player.port.remaining = 0
	player.starboard.remaining = 0
	player.fire_loaded()
	await frames(45)
	check(enemy.health < enemy.hull.max_health, "real projectile collision damages enemy")
	check(player.health == hp, "shots exclude their source hull")
	await frames(100)
	check(get_nodes_in_group("projectiles").is_empty(), "missed shots expire")
	# Island at (120,210) lies directly between these hulls.
	player.position = Vector2(-80,210)
	enemy.position = Vector2(320,210)
	enemy.health = enemy.hull.max_health
	player.port.remaining = 0
	player.starboard.remaining = 0
	await frames(2)
	player.fire_loaded()
	await frames(70)
	check(enemy.health == enemy.hull.max_health, "rock intercepts cannonballs")
	check(not enemy.ray(player.position,enemy.position,1).is_empty(), "AI sees rock occlusion")
	player.position = Vector2(120,350)
	player.rotation = 0
	player.speed = 100
	player.set_physics_process(true)
	key(KEY_W)
	await frames(80)
	key(KEY_W,false)
	check(player.position.y > 300, "ship cannot cross solid island")
	enemy.take_damage(1000)
	await frames(60)
	check(game.screen == "result" and paused, "enemy sinking produces paused victory")
	check(root.gui_get_focus_owner().text == "Sail again", "result keyboard focus")
	await tap(KEY_ENTER)
	check(game.screen == "battle" and not paused, "keyboard restart creates new battle")
	check(game.arena.player.health == 100 and game.arena.enemy.health == 100, "restart resets health")
	game.arena.player.take_damage(1000)
	await frames(60)
	check(game.screen == "result", "player sinking produces defeat")
	await tap(KEY_ESCAPE)
	check(game.screen == "menu" and not paused, "Escape returns from result to menu")
	# Use actual GUI hit testing rather than directly emitting a button signal.
	var button: Button = root.gui_get_focus_owner()
	# parse_input_event expects window pixels, including headless's 64x64 viewport.
	var point: Vector2 = root.get_final_transform() * button.get_global_rect().get_center()
	var click := InputEventMouseButton.new()
	click.position = point
	click.global_position = point
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	Input.parse_input_event(click)
	await frames(1)
	click = click.duplicate()
	click.pressed = false
	Input.parse_input_event(click)
	await frames(2)
	check(game.screen == "battle", "mouse click activates menu through GUI hit testing")
	print("RESULT: %d checks, %d failures" % [checks, failures])
	game.audio.shutdown()
	OS.delay_msec(150) # Audio mixer runs in wall time, not --fixed-fps simulation.
	await frames(3)
	game.queue_free()
	await frames(2)
	quit(1 if failures else 0)
