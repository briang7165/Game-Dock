extends SceneTree
var checks: int = 0
var failures: int = 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("PASS: " if ok else "FAIL: ",message)
func frames(count: int) -> void:
	for i: int in range(count):
		await physics_frame
		await process_frame
func run() -> void:
	var game: Node = preload("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	var data: Dictionary = CampaignSave.fresh("Test","Test",0,123)
	data.stop = 4
	for chapter: int in range(1,4):
		data.chapter = chapter
		game.start_battle(VoyageDirector.encounter(data))
		await frames(2)
		var boss: BroadsideShip = game.arena.enemy
		var player: BroadsideShip = game.arena.player
		boss.set_physics_process(false)
		player.set_physics_process(false)
		boss.position = Vector2.ZERO
		boss.rotation = 0
		player.position = Vector2(180,0)
		boss.speed = 0
		boss.turn_velocity = 0
		var ability: BossAbility = boss.ability
		check(boss.role == ["warden","corsair","regent"][chapter-1],"boss retains distinct role")
		ability.cooldown = 0
		boss.port.remaining = 0
		boss.starboard.remaining = 0
		ability.tick(boss,0.01,true,true)
		check(ability.phase == "warn" and ability.salvos == 0 and ability.timer >= 1.5,"special starts with visible warning, no instant hit")
		check(game.audio.last_frames.has(BossAbility.SPECS[boss.role].cue),"unique warning sound emitted")
		game.hud._process(0)
		check("WARNING" in game.hud.combat_status.text,"boss warning appears in reserved HUD")
		ability.tick(boss,ability.timer+0.01,true,true)
		if chapter == 1:
			check(ability.salvos == 1 and ability.phase == "second","Tidewarden releases first actual salvo")
			ability.tick(boss,0.4,true,true)
			check(ability.salvos == 1,"second volley is spaced apart")
			ability.tick(boss,0.6,true,true)
			check(ability.salvos == 2 and ability.phase == "rest","Tidewarden releases second actual salvo then recovers")
		elif chapter == 2:
			await frames(40)
			check(player.rigging_slow > 0 and player.health < 60,"Corsair chain cannonball hits and slows actual player")
			game.hud._process(0)
			check("RIGGING HIT" in game.hud.combat_status.text,"successful chain hit shows status countdown")
			player.step(2.1,0,0)
			check(player.rigging_slow == 0 and boss.guns.slow_seconds == 0,"slow expires and boss ordinary ammunition restored")
		else:
			check(ability.phase == "charge" and ability.salvos == 0,"Regent enters charge before heavy broadside")
			var before: Vector2 = boss.position
			for i: int in range(12):
				await physics_frame
				boss._physics_process(1.0/60)
			check(boss.position.distance_to(before) > 20 and absf(boss.rotation) < 0.05,"charge moves straight using real sailing and collision physics")
			ability.tick(boss,1.2,true,true)
			check(ability.phase == "release" and ability.timer >= 1,"heavy broadside has an additional warning")
			ability.tick(boss,1.1,true,false)
			var heavy: bool = false
			for child: Node in game.arena.get_children():
				if "stats" in child and child.stats is CannonStats: heavy = heavy or child.stats.damage == 20
			check(ability.salvos == 1 and heavy,"Regent commits real stronger broadside even if player dodges its line")
		check(ability.phase == "rest" and ability.cooldown >= 13,"special ends with vulnerability and long cooldown")
		var salvos: int = ability.salvos
		ability.tick(boss,2.1,true,true)
		boss.port.remaining = 0
		ability.tick(boss,0.1,true,true)
		check(ability.phase == "ready" and ability.salvos == salvos and ability.activations == 1,"special cannot repeat during cooldown")
		ability.cooldown = 0
		boss.position = Vector2(5000,0)
		boss._physics_process(0.02)
		check(ability.phase == "ready" and ability.salvos == salvos,"offscreen boss cannot begin special")
		boss.position = Vector2.ZERO
		ability.tick(boss,0.01,true,true)
		ability.tick(boss,3.0,false,true)
		check(ability.phase == "rest" and ability.salvos == salvos,"lost cover or visibility cancels warned special")
	# Compare actual steering/throttle requests, including reload disengagement.
	var enemy: BroadsideShip = game.arena.enemy
	enemy.ability = null
	enemy.role = "raider"
	enemy.port.remaining = 2
	enemy.starboard.remaining = 2
	enemy.maneuver_time = 7
	var raider: Vector2 = enemy.tactical_motion(Vector2(350,0),350)
	check(enemy.maneuver_phase == "disengage" and raider.y > 0.8,"raider disengages quickly while reloading")
	enemy.role = "hunter"
	var hunter: Vector2 = enemy.tactical_motion(Vector2(200,0),200)
	check(hunter.y < 0 and enemy.maneuver_phase == "retreat","hunter backs away from close danger")
	enemy.role = "heavy"
	var heavy_motion: Vector2 = enemy.tactical_motion(Vector2(350,0),350)
	check(heavy_motion.y < 0.2 and enemy.maneuver_phase == "hold firing zone","heavy holds a deliberate firing zone")
	var audio: Node = game.audio
	check(audio.music_tracks.size() == 3,"three offline music arrangements exist")
	for mode: String in audio.music_tracks:
		var stream: AudioStreamWAV = audio.music_tracks[mode].stream
		check(stream.loop_end == stream.data.size()/2 and abs(stream.data.decode_s16(0)-stream.data.decode_s16(stream.data.size()-2)) < 200,mode+" sample-exact loop has no seam jump")
	check(audio.music_tracks.harbor.stream.data != audio.music_tracks.battle.stream.data and audio.music_tracks.battle.stream.data != audio.music_tracks.boss.stream.data,"harbor, battle and boss arrangements differ")
	audio.set_context("harbor")
	audio._process(4)
	audio.set_context("boss")
	audio._process(0.1)
	check(audio.music_mix.harbor > 0 and audio.music_mix.boss > 0 and is_equal_approx(audio.music_mix.harbor+audio.music_mix.boss,1),"music crossfade overlaps gradually at constant total gain")
	audio._process(4)
	check(audio.music_mix.boss == 1 and audio.music_mix.harbor == 0,"crossfade settles on requested arrangement")
	game.show_menu()
	await frames(3)
	audio.shutdown()
	OS.delay_msec(150)
	game.queue_free()
	await frames(3)
	print("M2E RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
