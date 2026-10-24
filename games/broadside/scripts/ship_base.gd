class_name BroadsideShip
extends CharacterBody2D
signal sunk(ship: BroadsideShip)
signal salvo(ship: BroadsideShip, side: float)
@export var hull: HullStats = preload("res://data/sloop.tres")
@export var guns: CannonStats = preload("res://data/cannons.tres")
@export var enemy: bool = false
var pennant: int = 0
var ship_class: String = "sloop"
var hull_size := Vector2.ONE
var prow_rank: int = 0
var health: float
var speed: float = 0.0
var turn_velocity: float = 0.0
var drift: Vector2 = Vector2.ZERO
var port: CannonBattery
var starboard: CannonBattery
var telegraph: float = 0.0
var hit_flash: float = 0.0
var arena: Node2D
var dead: bool = false
var hull_shape: CollisionShape2D

func _ready() -> void:
	health = hull.max_health
	set_cannon_loadout(guns)
	collision_layer = 2
	collision_mask = 3
	var shape := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 20.0
	capsule.height = 78.0
	shape.shape = capsule
	add_child(shape)
	hull_shape = shape

func resize_hull(size: Vector2) -> void:
	hull_size = size
	var capsule := CapsuleShape2D.new()
	capsule.radius = 20*size.x
	capsule.height = 78*size.y
	hull_shape.shape = capsule
	queue_redraw()

func set_cannon_loadout(definition: CannonStats) -> bool:
	if definition == null or definition.gun_count < 1 or definition.gun_count > hull.cannon_capacity:
		return false
	var port_fraction: float = port.remaining/maxf(guns.reload_seconds,0.001) if port != null else 0.0
	var starboard_fraction: float = starboard.remaining/maxf(guns.reload_seconds,0.001) if starboard != null else 0.0
	guns = definition.duplicate()
	port = CannonBattery.new(guns,-1.0)
	starboard = CannonBattery.new(guns,1.0)
	port.remaining = port_fraction*guns.reload_seconds
	starboard.remaining = starboard_fraction*guns.reload_seconds
	queue_redraw()
	return true

func motion_velocity() -> Vector2:
	return Vector2.UP.rotated(rotation)*speed+drift

func step(delta: float, throttle: float, steering: float) -> void:
	if dead:
		return
	port.tick(delta)
	starboard.tick(delta)
	hit_flash = maxf(0.0, hit_flash - delta)
	var old_forward: Vector2 = Vector2.UP.rotated(rotation)
	var effectiveness: float = lerpf(hull.stationary_steering, 1.0, clampf(absf(speed) / hull.top_speed, 0.0, 1.0))
	var desired_turn: float = steering * hull.turn_rate * effectiveness
	turn_velocity = move_toward(turn_velocity, desired_turn, hull.rudder_acceleration * delta)
	rotation += turn_velocity * delta
	var forward: Vector2 = Vector2.UP.rotated(rotation)
	if throttle > 0.0:
		speed = move_toward(speed, hull.top_speed * throttle, hull.acceleration * delta)
	elif throttle < 0.0:
		speed = move_toward(speed, -hull.reverse_speed, hull.braking * delta)
	else:
		speed = move_toward(speed, 0.0, (hull.drag + speed * speed * hull.water_resistance) * delta)
	# Retain a little of the old heading's momentum, then resist lateral slip.
	drift += (old_forward - forward) * speed
	drift -= forward * drift.dot(forward)
	drift *= exp(-hull.lateral_drag * delta)
	drift = drift.limit_length(hull.max_drift)
	velocity = forward * speed + drift
	var before_slide: Vector2 = velocity
	move_and_slide()
	for i: int in range(get_slide_collision_count()):
		var collision: KinematicCollision2D = get_slide_collision(i)
		var other: Object = collision.get_collider()
		if other is CollisionObject2D:
			arena.impacts.report(self,other,collision.get_normal(),before_slide,collision.get_position())
	if get_slide_collision_count() > 0:
		speed *= 0.95
		drift = Vector2.ZERO
	queue_redraw()

func fire_loaded() -> int:
	if dead:
		return 0
	var shots: int = 0
	for battery: CannonBattery in [port, starboard]:
		if not battery.consume():
			continue
		salvo.emit(self, battery.side)
		arena.sound("cannon", global_position)
		for index: int in range(guns.gun_count):
			var projectile: Node2D = preload("res://scenes/Cannonball.tscn").instantiate()
			var angle: float = deg_to_rad(guns.spread_degrees) * (float(index) - float(guns.gun_count - 1) / 2.0)
			projectile.position = to_global(battery.muzzle(index))
			projectile.direction = Vector2(battery.side, 0).rotated(rotation + angle)
			projectile.source = self
			projectile.stats = guns
			arena.add_child(projectile)
			arena.effect(projectile.position, Color("ffcf78"), 12.0)
			shots += 1
	return shots

func take_damage(amount: float) -> void:
	if dead:
		return
	health = maxf(0.0, health - amount)
	hit_flash = 0.22
	if health <= 0.0:
		dead = true
		collision_layer = 0
		collision_mask = 0
		sunk.emit(self)

func _draw() -> void:
	# Original layered ink/wood/canvas illustration. Forward is local -Y.
	var outline := PackedVector2Array([Vector2(0,-48), Vector2(18,-29), Vector2(23,12), Vector2(15,37), Vector2(-15,37), Vector2(-23,12), Vector2(-18,-29)])
	for i: int in range(outline.size()):
		outline[i] *= hull_size
	draw_colored_polygon(outline, Color("182e32"))
	var inner := PackedVector2Array()
	for point: Vector2 in outline:
		inner.append(point * 0.86)
	draw_colored_polygon(inner, Color("96613d") if hit_flash <= 0 else Color("fff0bc"))
	for y: int in range(-24, 32, 7):
		draw_line(Vector2(-15,y), Vector2(15,y), Color("bd8753"), 2.0, true)
	for battery: CannonBattery in [port, starboard]:
		if battery == null:
			continue
		for index: int in range(guns.gun_count):
			var muzzle: Vector2 = battery.muzzle(index)
			muzzle.x -= battery.side * 5.0 * clampf((battery.remaining - guns.reload_seconds + 0.25) / 0.25, 0.0, 1.0)
			draw_line(muzzle - Vector2(battery.side * 10,0), muzzle, Color("202d35"), 6.0, true)
			if telegraph > 0.0:
				draw_circle(muzzle, 5.0 + telegraph * 4.0, Color("ffd78b"))
	draw_line(Vector2(0,-28), Vector2(0,27), Color("4c3529"), 4.0, true)
	draw_colored_polygon(PackedVector2Array([Vector2(-25,-17),Vector2(22,-17),Vector2(27,12),Vector2(0,18),Vector2(-24,10)]), Color("d8c89b"))
	draw_colored_polygon(PackedVector2Array([Vector2(-21,-15),Vector2(19,-15),Vector2(21,8),Vector2(0,12),Vector2(-19,7)]), Color("f1e1b8"))
	draw_line(Vector2(0,-16),Vector2(0,13),Color("aa9b76"),1.4,true)
	draw_colored_polygon(PackedVector2Array([Vector2(0,-30),Vector2(18,-25),Vector2(0,-20)]), Color("c55748") if enemy else [Color("42c7b7"),Color("e8c861"),Color("e6e0ce")][pennant])
	if ship_class != "sloop":
		# Extra masts and raised stern distinguish purchased hulls without replacing starter art.
		for mast_y: float in [-34.0,30.0] if ship_class in ["frigate","galleon"] else [30.0]:
			draw_line(Vector2(0,mast_y-10),Vector2(0,mast_y+12),Color("4c3529"),3,true)
			draw_colored_polygon(PackedVector2Array([Vector2(-18,mast_y-6),Vector2(18,mast_y-6),Vector2(20,mast_y+8),Vector2(-20,mast_y+8)]),Color("e5d4a4"))
		if ship_class == "galleon":
			draw_rect(Rect2(-20,43,40,10),Color("c79d52"))
	if prow_rank > 0:
		draw_line(Vector2(-9,-39*hull_size.y),Vector2(0,-50*hull_size.y),Color("abb7b6"),4,true)
		draw_line(Vector2(0,-50*hull_size.y),Vector2(9,-39*hull_size.y),Color("abb7b6"),4,true)
	if health < hull.max_health * 0.5:
		draw_line(Vector2(-12,23), Vector2(8,28), Color("332b27"),3.0,true)
	if absf(speed) > 20:
		draw_arc(Vector2(0,40),18,0.2,2.9,12,Color(0.7,0.9,0.86,0.5),2,true)
