extends SceneTree
var checks: int = 0
var failures: int = 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, text: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("PASS: " if ok else "FAIL: ",text)
func tick() -> void:
	await physics_frame
	await process_frame
func run() -> void:
	var game: Node = preload("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	for layout: int in range(5):
		var encounter := EncounterStats.new()
		encounter.campaign = true
		encounter.layout = layout
		encounter.enemy_roles.assign(["raider","hunter","heavy"])
		game.start_battle(encounter)
		await tick()
		var arena: Node2D = game.arena
		var player: BroadsideShip = arena.player
		player.set_physics_process(false)
		player.hull = player.hull.duplicate()
		player.hull.max_health = 100000
		player.health = 100000
		for hostile: BroadsideShip in arena.enemies: hostile.set_physics_process(false)
		var nav: SeaNavigation = arena.navigation
		var paths_clear: bool = true
		for rock: Dictionary in nav.obstacles:
			var start: Vector2 = nav.safe_point(rock.center+Vector2(0,rock.radius+130))
			var destination: Vector2 = nav.safe_point(rock.center-Vector2(0,rock.radius+180))
			var route: PackedVector2Array = nav.route(start,destination)
			paths_clear = paths_clear and not route.is_empty()
			for point: Vector2 in route:
				paths_clear = paths_clear and nav.clear(start,point)
				start = point
		check(paths_clear,"layout %d: planned routes clear every island envelope" % layout)
		var enemy: BroadsideShip = arena.enemy
		for role: String in ["raider","hunter","heavy","warden","corsair","regent"]:
			VoyageDirector.configure(enemy,role,encounter)
			enemy.health = 100000
			enemy.hull.max_health = 100000
			var rock: Dictionary = nav.obstacles[0]
			var start: Vector2 = rock.center+Vector2(0,rock.radius+85)
			enemy.position = start
			enemy.rotation = 0
			enemy.speed = 95
			enemy.drift = Vector2.ZERO
			enemy.waypoints.clear()
			enemy.escaping_shore = false
			enemy.turn_velocity = 0
			enemy.route_clock = 0
			enemy.recovery = 0
			enemy.progress_clock = 0
			enemy.last_position = start
			player.position = nav.safe_point(rock.center-Vector2(0,280))
			enemy.set_physics_process(true)
			var samples: Array[Vector2] = []
			var slow_windows: int = 0
			var worst: int = 0
			var farthest: float = 0
			var found_lane: bool = false
			var lane_time: float = -1
			for frame: int in range(3600):
				await tick()
				farthest = maxf(farthest,enemy.position.distance_to(start))
				found_lane = found_lane or nav.clear(enemy.position,player.position,20)
				if found_lane and lane_time < 0: lane_time = (frame+1)/60.0
				if frame % 120 == 119:
					samples.append(enemy.position)
					if samples.size() > 1:
						# A tactical pause or turn is not a terrain trap. Measure stalled
						# physical contact, and separately require a clear lane past shore.
						slow_windows = slow_windows+1 if samples[-1].distance_to(samples[-2]) < 12 and enemy.get_slide_collision_count() > 0 else 0
						worst = maxi(worst,slow_windows)
				if frame >= 1799 and found_lane: break
			check(farthest > 100 and found_lane and worst < 3,"layout %d %s: excursion %.0f, clear lane %.1fs, contact stall %ds" % [layout,role,farthest,lane_time,worst*2])
			enemy.set_physics_process(false)
		# All three roles move together around the same terrain, with real hull collisions.
		var fleet_start: Array[Vector2] = []
		for i: int in range(3):
			var hostile: BroadsideShip = arena.enemies[i]
			hostile.position = nav.safe_point(Vector2(-500+i*160,480))
			fleet_start.append(hostile.position)
			hostile.rotation = 0
			hostile.health = 100000
			hostile.hull.max_health = 100000
			hostile.waypoints.clear()
			hostile.escaping_shore = false
			hostile.set_physics_process(true)
		player.position = Vector2(150,-100)
		for frame: int in range(1200): await tick()
		var kept_in_sea: bool = true
		for i: int in range(3):
			var hostile: BroadsideShip = arena.enemies[i]
			kept_in_sea = kept_in_sea and absf(hostile.position.x) < 1250 and absf(hostile.position.y) < 950 and hostile.position.distance_to(fleet_start[i]) > 70
		check(kept_in_sea,"layout %d: three-ship traffic advances inside navigable sea" % layout)
		game.show_menu()
		await tick()
	game.start_battle()
	await tick()
	var arena: Node2D = game.arena
	arena.enemy.set_physics_process(false)
	var player: BroadsideShip = arena.player
	player.set_physics_process(false)
	var edge_safe: bool = true
	for direction: Vector2 in [Vector2.RIGHT,Vector2.LEFT,Vector2.UP,Vector2.DOWN]:
		player.position = direction*Vector2(1100,800)
		player.rotation = direction.angle()+PI/2
		player.speed = player.hull.top_speed
		player.drift = Vector2.ZERO
		var hp: float = player.health
		for frame: int in range(240):
			player.step(1.0/60,1,0)
			await tick()
		edge_safe = edge_safe and absf(player.position.x) < 1200 and absf(player.position.y) < 900 and player.health == hp
		for frame: int in range(240):
			player.step(1.0/60,1,1)
			await tick()
		edge_safe = edge_safe and absf(angle_difference(player.rotation,direction.angle()+PI/2)) > 0.5
	check(edge_safe,"four soft boundaries contain full throttle without damage and retain steering")
	var boss: BroadsideShip = arena.enemy
	var info := EncounterStats.new()
	info.campaign = true
	arena.encounter = info
	player.position = Vector2(400,0)
	player.health = 100000
	for role: String in ["raider","hunter","heavy","warden","corsair","regent"]:
		VoyageDirector.configure(boss,role,info)
		boss.position = Vector2(1100,0)
		boss.rotation = PI/2
		boss.speed = 180
		boss.drift = Vector2.ZERO
		boss.turn_velocity = 0
		boss.waypoints.clear()
		boss.escaping_shore = false
		boss.returning_from_edge = false
		if role == "regent":
			boss.ability.phase = "charge"
			boss.ability.charge_heading = boss.rotation
		boss.set_physics_process(true)
		for frame: int in range(900): await tick()
		check(boss.position.x < 980 and (boss.ability == null or boss.ability.phase != "charge"),role+" turns inward at the soft edge (including boss charge)")
		boss.set_physics_process(false)
	game.show_menu()
	game.audio.shutdown()
	OS.delay_msec(150)
	game.queue_free()
	await tick()
	print("M2G NAVIGATION RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
