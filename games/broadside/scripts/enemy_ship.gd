extends BroadsideShip
@export var tactics: EncounterStats = preload("res://data/encounter.tres")
var target: BroadsideShip
var warning: float = 0.0
var stuck_time: float = 0.0
var recovery: float = 0.0
var last_position: Vector2

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target) or target.dead or dead:
		return
	var offset: Vector2 = target.position - position
	var distance: float = offset.length()
	var desired: float = offset.angle() + PI / 2.0
	if distance < tactics.ai_range:
		# Choose the closer of the two hull headings perpendicular to target.
		var a: float = offset.angle()
		var b: float = a + PI
		desired = a if absf(angle_difference(rotation, a)) < absf(angle_difference(rotation, b)) else b
	var heading: Vector2 = Vector2.UP.rotated(rotation)
	var ahead: Dictionary = ray(position, position + heading * 150.0, 1)
	var throttle: float = tactics.ai_throttle if distance > tactics.ai_range else 0.28
	var steering: float = clampf(angle_difference(rotation, desired) * 2.4, -1, 1)
	if not ahead.is_empty():
		# Pick the clearest side; normal points away from the obstacle.
		var normal: Vector2 = ahead.normal
		var avoidance: Vector2 = (normal + heading.rotated(PI / 2.0) * 0.7).normalized()
		steering = clampf(angle_difference(rotation, avoidance.angle() + PI / 2.0) * 3.0, -1, 1)
		throttle = 0.35
	if position.distance_to(last_position) < 0.2 and throttle > 0.0:
		stuck_time += delta
	else:
		stuck_time = 0.0
	last_position = position
	if stuck_time > 1.2:
		recovery = 1.5
		stuck_time = 0.0
	if recovery > 0.0:
		recovery -= delta
		throttle = -1.0
		steering = 1.0
	var side: float = signf(Vector2.RIGHT.rotated(rotation).dot(offset))
	var battery: CannonBattery = starboard if side > 0 else port
	var aligned: bool = absf(heading.dot(offset.normalized())) < tactics.ai_fire_angle
	var clear: bool = ray(position, target.position, 1).is_empty()
	if aligned and clear and distance < guns.projectile_speed * guns.projectile_lifetime * 0.85 and battery.ready():
		warning += delta
		throttle = 0.0
		steering = 0.0
		if warning >= tactics.ai_telegraph:
			fire_loaded()
			warning = 0.0
	else:
		warning = 0.0
	telegraph = warning / tactics.ai_telegraph
	step(delta, throttle, steering)

func ray(from: Vector2, to: Vector2, mask: int) -> Dictionary:
	return get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(from, to, mask, [get_rid()]))
