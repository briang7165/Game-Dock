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

func fresh() -> void:
	game.start_battle()
	game.arena.enemy.set_physics_process(false)
	game.arena.player.set_physics_process(false)
	await frames(2)

func run() -> void:
	game = preload("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await fresh()
	var player: BroadsideShip = game.arena.player
	var enemy: BroadsideShip = game.arena.enemy
	check(player.guns.gun_count == 1 and enemy.guns.gun_count == 1,"both explicit starter loadouts have one cannon per side")
	player.port.remaining = 1.0
	var upgrade: CannonStats = player.guns.duplicate()
	upgrade.gun_count = 2
	check(player.set_cannon_loadout(upgrade),"capacity accepts explicit two-gun configuration for future upgrades")
	check(player.port.remaining == 1.0 and enemy.guns.gun_count == 1,"configuration preserves reload and does not change enemy")
	upgrade.gun_count = 3
	check(not player.set_cannon_loadout(upgrade) and player.guns.gun_count == 2,"over-capacity configuration rejected without mutation")
	await fresh()
	player = game.arena.player
	var hud: Control = game.hud
	player.port.remaining = player.guns.reload_seconds * 0.75
	player.starboard.remaining = 0
	player.take_damage(20)
	await frames(1)
	check(hud.port_bar.value == 25 and hud.starboard_bar.value == 100,"HUD independently reads actual port and starboard reloads")
	check(hud.starboard_state.text == "READY" and "%" in hud.port_state.text,"readiness and countdown percentage use text as well as color")
	check(hud.hull_label.text == "40 / 60 HP" and hud.hull_bar.value > 40,"hull number updates immediately while bar eases")
	check(hud.flash > 0,"damage briefly highlights HUD")
	await frames(20)
	check(hud.hull_bar.value == 40,"hull display converges to actual health")
	player.take_damage(30)
	await frames(1)
	check("CRITICAL" in hud.hull_title.text,"low health has an explicit critical warning")
	check(hud.bottom.get_global_rect().end.y <= root.get_visible_rect().size.y and hud.bottom.anchor_bottom == 1,"HUD remains bottom anchored inside viewport")
	check(hud.mouse_filter == Control.MOUSE_FILTER_IGNORE and hud.hull_bar.focus_mode == Control.FOCUS_NONE,"HUD cannot consume combat input")
	game.pause_battle()
	var displayed: float = hud.hull_bar.value
	await frames(20)
	check(hud.hull_bar.value == displayed,"pause freezes health animation")
	game.resume_battle()
	var stats: ImpactStats = game.arena.impacts.stats
	check(stats.damage_for_speed(20) == 0 and stats.damage_for_speed(35) == 0,"gentle impacts and threshold are harmless")
	check(stats.damage_for_speed(100) > stats.damage_for_speed(50),"impact damage increases with closing speed")
	check(stats.damage_for_speed(10000) == stats.maximum_damage,"damage is capped for extreme impacts")
	await fresh()
	player = game.arena.player
	player.position = Vector2(120,335)
	player.speed = 20
	for i: int in range(90):
		player.step(1.0/60,0,0)
		await frames(1)
	check(player.health == player.hull.max_health,"actual gentle island approach does not damage the hull")
	# Actual move_and_slide rock contact, including four seconds holding throttle.
	await fresh()
	player = game.arena.player
	player.position = Vector2(120,410)
	player.rotation = 0
	player.speed = 165
	for i: int in range(120):
		player.step(1.0/60,1,0)
		await frames(1)
		if player.health < player.hull.max_health:
			break
	check(player.health < player.hull.max_health and player.health >= player.hull.max_health-stats.maximum_damage,"real high-speed island collision damages the hull within cap")
	var health: float = player.health
	for i: int in range(240):
		player.step(1.0/60,1,0)
		await frames(1)
	check(player.health == health,"sustained throttle against rock cannot repeatedly drain health")
	player.position = Vector2(120,410)
	player.speed = 0
	await frames(60)
	player.speed = 165
	for i: int in range(120):
		player.step(1.0/60,1,0)
		await frames(1)
		if player.health < health:
			break
	check(player.health < health,"separation and cooldown rearm a new rock impact")
	# Real ship contact: striking a stationary hull damages both only once.
	await fresh()
	player = game.arena.player
	enemy = game.arena.enemy
	player.position = Vector2(-700,500)
	enemy.position = Vector2(-550,500)
	player.rotation = PI/2
	player.speed = 165
	for i: int in range(120):
		player.step(1.0/60,1,0)
		await frames(1)
		if player.health < player.hull.max_health:
			break
	check(player.health < player.hull.max_health and is_equal_approx(player.health,enemy.health),"actual ram damages attacker and stationary target equally")
	health = player.health
	for i: int in range(180):
		player.step(1.0/60,1,0)
		await frames(1)
	check(player.health == health and enemy.health == health,"sustained ship contact causes no repeated ram damage")
	# Deterministic relative-velocity snapshots and reversed collision reports.
	for reverse: bool in [false,true]:
		await fresh()
		player = game.arena.player
		enemy = game.arena.enemy
		player.rotation = PI/2
		enemy.rotation = -PI/2
		player.speed = 60
		enemy.speed = 60
		var ships: Array[BroadsideShip] = [player,enemy]
		game.arena.impacts.begin_frame(1.0/60,ships)
		var damage: float
		if reverse:
			damage = game.arena.impacts.report(enemy,player,Vector2.RIGHT,enemy.motion_velocity(),enemy.position)
		else:
			damage = game.arena.impacts.report(player,enemy,Vector2.LEFT,player.motion_velocity(),player.position)
		check(is_equal_approx(damage,stats.damage_for_speed(120)),"head-on relative speeds combine independent of callback order")
		game.arena.impacts.report(enemy,player,Vector2.RIGHT,enemy.motion_velocity(),enemy.position)
		game.arena.impacts.report(player,enemy,Vector2.LEFT,player.motion_velocity(),player.position)
		check(is_equal_approx(player.health,player.hull.max_health-damage) and is_equal_approx(enemy.health,enemy.hull.max_health-damage),"duplicate reports deduplicate the unordered pair")
	await fresh()
	player = game.arena.player
	enemy = game.arena.enemy
	player.speed = 150
	var ships: Array[BroadsideShip] = [player,enemy]
	game.arena.impacts.begin_frame(0,ships)
	check(game.arena.impacts.report(player,enemy,Vector2.RIGHT,Vector2.UP*150,player.position) == 0,"fast tangential glancing motion causes no crash damage")
	await fresh()
	player = game.arena.player
	enemy = game.arena.enemy
	player.health = 1
	enemy.health = 1
	player.speed = 150
	ships = [player,enemy]
	game.arena.impacts.begin_frame(0,ships)
	game.pause_battle()
	check(game.arena.impacts.report(player,enemy,Vector2.DOWN,Vector2.UP*150,player.position) == 0 and player.health == 1,"paused contact cannot apply damage")
	game.resume_battle()
	game.arena.impacts.report(player,enemy,Vector2.DOWN,Vector2.UP*150,player.position)
	check(player.dead and enemy.dead,"lethal ram sinks both ships safely")
	await frames(60)
	check(game.screen == "result" and game.panel.find_children("*","Label",true,false)[1].text == "Lost at sea","mutual sinking resolves to one defeat result")
	await fresh()
	player = game.arena.player
	player.health = 1
	player.position = Vector2(120,410)
	player.speed = 165
	for i: int in range(120):
		player.step(1.0/60,1,0)
		await frames(1)
		if player.dead:
			break
	await frames(60)
	check(player.dead and game.screen == "result","lethal physical rock impact follows the existing defeat path")
	paused = false
	game.audio.shutdown()
	OS.delay_msec(150)
	await frames(3)
	game.queue_free()
	await frames(3)
	print("M12 RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
