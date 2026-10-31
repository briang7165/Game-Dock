extends SceneTree
var game: Node
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print("PASS: " if ok else "FAIL: ",message)

func frames(count: int) -> void:
	for i: int in range(count):
		await physics_frame
		await process_frame

func run() -> void:
	game = preload("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	# Controlled open-water volleys use real projectiles, with neither hull moving.
	# This measures mechanical lethality, not ordinary human encounter duration.
	for enemy_shoots: bool in [false,true]:
		game.start_battle()
		var player: BroadsideShip = game.arena.player
		var enemy: BroadsideShip = game.arena.enemy
		player.set_physics_process(false)
		enemy.set_physics_process(false)
		var shooter: BroadsideShip = enemy if enemy_shoots else player
		var target: BroadsideShip = player if enemy_shoots else enemy
		shooter.position = Vector2(-700,500)
		target.position = Vector2(-400,500)
		shooter.rotation = 0
		target.rotation = 0
		await frames(2)
		check(shooter.health == 60 and target.health == 60,"both starting hulls use the explicit 60 HP test preset")
		check(shooter.guns.damage == 16 and shooter.guns.gun_count == 1,"each side uses one 16-damage cannon")
		check(shooter.guns.reload_seconds == 3 and enemy.tactics.ai_telegraph >= 0.9,"three-second reload and fair AI warning preserved")
		for hit: int in range(1,5):
			shooter.fire_loaded()
			for tick: int in range(190):
				shooter.port.tick(1.0/60)
				shooter.starboard.tick(1.0/60)
				await frames(1)
				if tick == 89:
					check(target.health == maxf(0,60-16*hit) and target.dead == (hit == 4),"real cannon hit %d leaves expected HP and sinking state" % hit)
		check(game.screen == "result" and paused,"four clean hits reach the existing result screen")
		var labels: Array[Node] = game.panel.find_children("*","Label",true,false)
		check(labels[1].text == ("Lost at sea" if enemy_shoots else "Victory"),"four-hit result has correct winner")
		print("CONTROLLED VOLLEY: fourth hit observed by 11.0 simulated seconds; stationary 300-unit target; enemy_shoots=",enemy_shoots)
	game.start_battle()
	check(game.arena.impacts.stats.maximum_damage <= game.arena.player.hull.max_health*0.3,"crash cap is at most 30 percent of fresh starter HP")
	# Passive-player observation keeps live AI, navigation, projectiles and impacts.
	var elapsed: int = 0
	while not game.arena.finished and elapsed < 10800:
		await frames(1)
		elapsed += 1
	print("PASSIVE PLAYER OBSERVATION: %.2f simulated seconds; ended=%s player_hp=%.2f enemy_hp=%.2f" % [elapsed/60.0,game.arena.finished,game.arena.player.health,game.arena.enemy.health])
	check(game.arena.finished,"live AI can resolve an unarmed passive-player encounter within observation window")
	paused = false
	game.audio.shutdown()
	OS.delay_msec(150)
	await frames(3)
	game.queue_free()
	await frames(3)
	print("BALANCE RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
