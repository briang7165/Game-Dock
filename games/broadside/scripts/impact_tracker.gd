extends RefCounted
## Arena-owned, unordered contact pairs. A cooldown alone must not farm damage
## while a player continues pressing into a wall: separation also is required.
var stats: ImpactStats = preload("res://data/impacts.tres")
var contacts: Dictionary = {}
var starting_velocities: Dictionary = {}
var time: float = 0.0

func begin_frame(delta: float, ships: Array[BroadsideShip]) -> void:
	time += delta
	starting_velocities.clear()
	for ship: BroadsideShip in ships:
		starting_velocities[ship.get_instance_id()] = ship.motion_velocity()
	for key: String in contacts.keys():
		var contact: Dictionary = contacts[key]
		var a: BroadsideShip = contact.a
		var b: CollisionObject2D = contact.b
		if not is_instance_valid(a) or not is_instance_valid(b) or a.dead or (b is BroadsideShip and b.dead):
			contacts.erase(key)
			continue
		var query := PhysicsShapeQueryParameters2D.new()
		query.shape = a.hull_shape.shape
		query.transform = a.hull_shape.global_transform
		query.margin = stats.contact_margin
		query.collision_mask = 3
		query.exclude = [a.get_rid()]
		var touching: bool = false
		for hit: Dictionary in a.get_world_2d().direct_space_state.intersect_shape(query,16):
			if hit.collider == b:
				touching = true
				break
		contact.separated = 0.0 if touching else float(contact.separated)+delta
		if contact.separated >= stats.separation_seconds and time >= contact.next_allowed:
			contacts.erase(key)

func report(ship: BroadsideShip, other: CollisionObject2D, normal: Vector2, before_slide: Vector2, at: Vector2) -> float:
	if ship.dead or (other is BroadsideShip and other.dead) or ship.get_tree().paused or ship.arena.finished:
		return 0.0
	if not (other is BroadsideShip) and (other.collision_layer & 1) == 0:
		return 0.0
	var first: int = mini(ship.get_instance_id(),other.get_instance_id())
	var second: int = maxi(ship.get_instance_id(),other.get_instance_id())
	var key: String = "%d:%d" % [first,second]
	if contacts.has(key):
		return 0.0
	# Snapshot both ships before either resolves movement; node order cannot
	# erase the struck vessel's velocity and halve a head-on ram's severity.
	var relative: Vector2 = before_slide
	if other is BroadsideShip:
		relative = starting_velocities.get(ship.get_instance_id(),before_slide) - starting_velocities.get(other.get_instance_id(),other.motion_velocity())
	var closing: float = maxf(0.0,-relative.dot(normal.normalized()))
	contacts[key] = {"a":ship,"b":other,"next_allowed":time+stats.cooldown_seconds,"separated":0.0}
	var damage: float = stats.damage_for_speed(closing)
	if damage <= 0.0:
		return 0.0
	# Record pair first; both reports and simultaneous lethal hits are safe.
	if other is BroadsideShip:
		ship.take_damage(damage*(1-0.15*ship.prow_rank)*(1+0.2*other.prow_rank))
		other.take_damage(damage*(1-0.15*other.prow_rank)*(1+0.2*ship.prow_rank))
	else:
		ship.take_damage(damage)
	ship.arena.effect(at,Color("e5c89b"),18.0+damage)
	ship.arena.sound("wood" if other is BroadsideShip else "rock",at)
	return damage
