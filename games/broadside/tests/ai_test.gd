extends SceneTree
var failures: int = 0
var salvos: int = 0
var telegraphed: bool = false
var game: Node

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, text: String) -> void:
	print("PASS: " if condition else "FAIL: ", text)
	if not condition:
		failures += 1

func tick() -> void:
	await physics_frame
	await process_frame

func on_salvo(ship: BroadsideShip, _side: float) -> void:
	salvos += 1
	if ship.telegraph > 0.5:
		telegraphed = true

func run() -> void:
	game = preload("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	game.start_battle()
	var player: BroadsideShip = game.arena.player
	var enemy: BroadsideShip = game.arena.enemy
	enemy.salvo.connect(on_salvo)
	# Keep duel running for three simulated minutes; record actual damage separately.
	var damage_seen: bool = false
	var peak_projectiles: int = 0
	var start: Vector2 = enemy.position
	for frame: int in range(10800):
		await tick()
		if player.health < player.hull.max_health:
			damage_seen = true
		player.health = player.hull.max_health
		peak_projectiles = maxi(peak_projectiles,get_nodes_in_group("projectiles").size())
	check(enemy.position.distance_to(start) > 50, "AI approaches and maneuvers")
	check(salvos >= 4, "AI repeatedly aligns and fires its own broadside (%d sides)" % salvos)
	check(telegraphed, "AI announces shots before firing")
	check(damage_seen, "AI can hit a player with actual projectiles")
	check(peak_projectiles <= 12, "projectile count remains bounded over 180 simulated seconds")
	# Occluded, aligned stationary setup must not fire through a rock.
	enemy.position = Vector2(320,210)
	player.position = Vector2(-80,210)
	enemy.rotation = 0
	enemy.speed = 0
	enemy.port.remaining = 0
	enemy.starboard.remaining = 0
	var old_salvos: int = salvos
	for frame: int in range(30):
		await tick()
	check(salvos == old_salvos, "AI with rock-occluded target does not fire")
	# Head directly into an island and allow steering/recovery to get clear.
	enemy.position = Vector2(120,340)
	enemy.rotation = 0
	enemy.speed = 130
	player.position = Vector2(120,-200)
	for frame: int in range(1800):
		await tick()
	check(enemy.position.distance_to(Vector2(120,340)) > 100, "AI escapes an island approach within 30 simulated seconds")
	print("AI RESULT: failures=",failures," peak_projectiles=",peak_projectiles)
	game.queue_free()
	await tick()
	quit(1 if failures else 0)
