extends Node2D
signal battle_ended(victory: bool)
var player: BroadsideShip
var enemy: BroadsideShip
var enemies: Array[BroadsideShip] = []
var finished: bool = false
var camera: Camera2D
var audio: Node
var impacts: RefCounted = preload("res://scripts/impact_tracker.gd").new()
@export var encounter: EncounterStats = preload("res://data/encounter.tres")

func _ready() -> void:
	process_physics_priority = -100
	for location: Vector2 in VoyageDirector.islands(encounter) if encounter.campaign else [Vector2(-420,-230),Vector2(120,210),Vector2(570,-280)]:
		var island: StaticBody2D = preload("res://scenes/Island.tscn").instantiate()
		island.position = location
		if encounter.campaign: island.theme = encounter.theme
		add_child(island)
	for bounds: Rect2 in [Rect2(-1220,-920,2440,60),Rect2(-1220,860,2440,60),Rect2(-1220,-860,60,1720),Rect2(1160,-860,60,1720)]:
		var body := StaticBody2D.new()
		body.collision_layer = 1
		body.position = bounds.get_center()
		var shape := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = bounds.size
		shape.shape = rectangle
		body.add_child(shape)
		add_child(body)
	player = preload("res://scenes/PlayerShip.tscn").instantiate()
	player.position = Vector2(-290,30)
	player.arena = self
	add_child(player)
	var spawns: Array[Vector2] = [Vector2(290,-70),Vector2(700,-70),Vector2(450,500)]
	for i: int in range(encounter.enemy_roles.size() if encounter.campaign else 1):
		var hostile: BroadsideShip = preload("res://scenes/EnemyShip.tscn").instantiate()
		hostile.position = spawns[i]
		hostile.rotation = PI
		hostile.arena = self
		hostile.target = player
		add_child(hostile)
		hostile.add_to_group("hostile_ships")
		if encounter.campaign: VoyageDirector.configure(hostile,encounter.enemy_roles[i],encounter)
		# Stagger warnings without reducing a ship's visible reaction time.
		hostile.port.remaining = i*0.65
		hostile.starboard.remaining = i*0.65
		hostile.sunk.connect(_ship_sunk)
		enemies.append(hostile)
	enemy = enemies[0]
	player.sunk.connect(_ship_sunk)
	camera = Camera2D.new()
	camera.zoom = Vector2.ONE * encounter.camera_zoom
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 4.0
	camera.limit_left = -1200
	camera.limit_right = 1200
	camera.limit_top = -900
	camera.limit_bottom = 900
	player.add_child(camera)

func _physics_process(delta: float) -> void:
	if not finished:
		var ships: Array[BroadsideShip] = [player]
		ships.append_array(enemies)
		impacts.begin_frame(delta,ships)

func _ship_sunk(ship: BroadsideShip) -> void:
	sound("sink", ship.global_position)
	effect(ship.position,Color("d4d5bc"),70.0)
	ship.set_physics_process(false)
	var all_sunk: bool = true
	for hostile: BroadsideShip in enemies: all_sunk = all_sunk and hostile.dead
	var end_now: bool = not finished and (player.dead or all_sunk)
	if end_now:
		finished = true
		player.set_physics_process(false)
		player.set_process_unhandled_key_input(false)
		for hostile: BroadsideShip in enemies: hostile.set_physics_process(false)
	var sinking := create_tween().set_parallel(true)
	sinking.tween_property(ship, "scale", Vector2(0.4,0.4), 0.75)
	sinking.tween_property(ship, "modulate:a", 0.0, 0.75)
	sinking.tween_property(ship, "rotation", ship.rotation + 0.4, 0.75)
	if end_now:
		# Re-evaluate after this physics frame: mutual destruction remains defeat.
		sinking.chain().tween_callback(func() -> void: battle_ended.emit(not player.dead))

func sound(kind: String, at: Vector2) -> void:
	if is_instance_valid(audio):
		audio.play_effect(kind, clampf(1.0 - player.global_position.distance_to(at) / 1600.0, 0.2, 1.0))

func effect(at: Vector2, color: Color, size: float) -> void:
	var burst := Node2D.new()
	burst.set_script(preload("res://scripts/effect.gd"))
	burst.position = at
	burst.tint = color
	burst.radius = size
	add_child(burst)
