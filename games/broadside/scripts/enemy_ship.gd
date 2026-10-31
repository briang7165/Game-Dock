extends BroadsideShip
@export var tactics: EncounterStats = preload("res://data/encounter.tres")
var role: String = "raider"
var ability: BossAbility
var maneuver_time: float = 0.0
var maneuver_phase: String = "approach"
var target: BroadsideShip
var warning: float = 0.0
var stuck_time: float = 0.0
var recovery: float = 0.0
var last_position: Vector2

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target) or target.dead or dead:
		return
	maneuver_time += delta
	var offset: Vector2 = target.position - position
	var distance: float = offset.length()
	var desired: float = offset.angle() + PI / 2.0
	if distance < tactics.ai_range:
		# Choose the closer of the two hull headings perpendicular to target.
		var a: float = offset.angle()
		var b: float = a + PI
		desired = a if absf(angle_difference(rotation, a)) < absf(angle_difference(rotation, b)) else b
	var heading: Vector2 = Vector2.UP.rotated(rotation)
	var ahead: Dictionary = ray(position, position + heading * tactics.obstacle_lookahead, 1)
	var throttle: float = tactics.ai_throttle if distance > tactics.ai_range else 0.45
	if arena.encounter.campaign:
		var movement: Vector2 = tactical_motion(offset,distance)
		desired = movement.x
		throttle = movement.y
		if ability != null:
			if ability.phase == "charge":
				desired = ability.charge_heading
				speed = maxf(speed,hull.top_speed*1.45)
				throttle = 0.0
			elif ability.phase == "rest": throttle = 0.1
	var steering: float = clampf(angle_difference(rotation, desired) * 2.4, -1, 1)
	if not ahead.is_empty():
		if ability != null and ability.phase == "charge": ability.finish()
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
		recovery = 2.5
		stuck_time = 0.0
	if recovery > 0.0:
		recovery -= delta
		throttle = -1.0
		steering = 1.0
	var side: float = signf(Vector2.RIGHT.rotated(rotation).dot(offset))
	var battery: CannonBattery = starboard if side > 0 else port
	var aligned: bool = absf(heading.dot(offset.normalized())) < tactics.ai_fire_angle
	var clear: bool = ray(position, target.position, 1).is_empty()
	if arena.encounter.campaign:
		# Visible warning before any campaign volley; no unseen offscreen sniper.
		var visible: Rect2 = get_viewport_rect()
		clear = clear and visible.size.x > 40 and visible.size.y > 40
		if clear: clear = visible.grow(-20).has_point(get_global_transform_with_canvas().origin)
	# Keep the warning latched through small heading changes caused by rudder lag.
	# Recheck cover/range throughout and alignment at release; no shot swivels.
	var in_range: bool = distance < guns.projectile_speed * guns.projectile_lifetime * 0.85
	var special_busy: bool = ability.tick(self,delta,clear and in_range,aligned) if ability != null else false
	if not special_busy and (aligned or warning > 0.0) and clear and in_range and battery.ready():
		warning += delta
		if warning >= tactics.ai_telegraph:
			if absf(heading.dot(offset.normalized())) < tactics.ai_fire_angle * 1.8:
				fire_loaded()
			warning = 0.0
	else:
		warning = 0.0
	telegraph = warning / tactics.ai_telegraph
	step(delta, throttle, steering)

func ray(from: Vector2, to: Vector2, mask: int) -> Dictionary:
	return get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(from, to, mask, [get_rid()]))

func tactical_motion(offset: Vector2, distance: float) -> Vector2:
	var archetype: String = {"warden":"heavy","corsair":"hunter","regent":"heavy"}.get(role,role)
	var aim: Vector2 = offset
	if archetype == "hunter":
		# Lead a moving ship by at most 90 units; guns still fire straight from the hull.
		aim += target.motion_velocity().limit_length(100)*minf(distance/maxf(guns.projectile_speed,1),0.9)
	var approach: float = aim.angle()+PI/2
	var tangent: float = aim.angle()
	if absf(angle_difference(rotation,tangent+PI)) < absf(angle_difference(rotation,tangent)): tangent += PI
	match archetype:
		"raider":
			if distance > 540: maneuver_phase = "flank"; return Vector2(approach+0.35,0.95)
			if fmod(maneuver_time,9.0) > 5.5 and not (port.ready() or starboard.ready()):
				maneuver_phase = "disengage"
				return Vector2(approach+PI*0.75,0.9)
			maneuver_phase = "circle"
			return Vector2(tangent+(0.16 if distance > 340 else -0.12),0.65)
		"hunter":
			if distance < 300: maneuver_phase = "retreat"; return Vector2(approach,-0.85)
			maneuver_phase = "keep distance"
			return Vector2(approach if distance > 620 else tangent,0.75 if distance > 620 else 0.28)
		_:
			maneuver_phase = "hold firing zone" if distance < 500 else "advance"
			return Vector2(tangent if distance < 500 else approach,0.12 if distance < 500 else 0.5)

func _draw() -> void:
	super._draw()
	if ability != null and ability.phase in ["warn","second","charge","release"]:
		var color := Color("ffe097") if ability.role != "corsair" else Color("8ee5df")
		draw_arc(Vector2.ZERO,70,0,TAU,48,color,3,true)
		if ability.role == "regent" and ability.phase in ["warn","charge"]: draw_line(Vector2.ZERO,Vector2(0,-180),color,6,true)
