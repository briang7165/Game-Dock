extends Node2D
signal battle_ended(victory: bool)
var player: BroadsideShip
var enemy: BroadsideShip
var finished: bool = false
var camera: Camera2D
var audio: Node
var impacts: RefCounted = preload("res://scripts/impact_tracker.gd").new()
@export var encounter: EncounterStats = preload("res://data/encounter.tres")

func _ready() -> void:
	process_physics_priority = -100
	for location: Vector2 in [Vector2(-420,-230),Vector2(120,210),Vector2(570,-280)]:
		var island: StaticBody2D = preload("res://scenes/Island.tscn").instantiate()
		island.position = location
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
	enemy = preload("res://scenes/EnemyShip.tscn").instantiate()
	enemy.position = Vector2(290,-70)
	enemy.rotation = PI
	enemy.arena = self
	enemy.target = player
	add_child(enemy)
	enemy.add_to_group("hostile_ships")
	player.sunk.connect(_ship_sunk)
	enemy.sunk.connect(_ship_sunk)
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
		var ships: Array[BroadsideShip] = [player,enemy]
		impacts.begin_frame(delta,ships)

func _ship_sunk(ship: BroadsideShip) -> void:
	sound("sink", ship.global_position)
	effect(ship.position,Color("d4d5bc"),70.0)
	var first_sinking: bool = not finished
	finished = true
	player.set_physics_process(false)
	player.set_process_unhandled_key_input(false)
	enemy.set_physics_process(false)
	var sinking := create_tween().set_parallel(true)
	sinking.tween_property(ship, "scale", Vector2(0.4,0.4), 0.75)
	sinking.tween_property(ship, "modulate:a", 0.0, 0.75)
	sinking.tween_property(ship, "rotation", ship.rotation + 0.4, 0.75)
	if first_sinking:
		# Mutual destruction is a defeat regardless of physics callback order.
		sinking.chain().tween_callback(func() -> void: battle_ended.emit(enemy.dead and not player.dead))

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
