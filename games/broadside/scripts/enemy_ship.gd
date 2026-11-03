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
var progress_clock: float = 0.0
var route_clock: float = 0.0
var waypoints := PackedVector2Array()
var avoidance_side: float = 1.0
var escaping_shore: bool = false
var shore_target: Vector2
var returning_from_edge: bool = false

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
	var throttle: float = tactics.ai_throttle if distance > tactics.ai_range else 0.18
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
	var motion: Vector2 = navigate(delta,desired,throttle)
	steering = motion.x
	throttle = motion.y
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

func navigate(delta: float, desired: float, throttle: float) -> Vector2:
	route_clock -= delta
	progress_clock += delta
	var nav: SeaNavigation = arena.navigation
	if absf(position.x) > 980 or absf(position.y) > 680:
		if not returning_from_edge: waypoints.clear()
		returning_from_edge = true
	elif absf(position.x) < 850 and absf(position.y) < 550:
		returning_from_edge = false
	var edge: bool = returning_from_edge
	var heading: Vector2 = Vector2.UP.rotated(rotation)
	var look: float = maxf(170,absf(speed)*2.1)
	# A hull already close to shore must first move OUT of the clearance envelope.
	# Reversing merely because a lookahead starts inside it can back into the rock.
	if not escaping_shore and not nav.point_clear(position):
		escaping_shore = true
		var safe: Vector2 = nav.safe_point(position)
		shore_target = nav.safe_point(safe+(safe-position).normalized()*110)
		waypoints.clear()
	if escaping_shore and nav.clear(position,position,SeaNavigation.CLEARANCE+65):
		escaping_shore = false
	if escaping_shore:
		var outward: Vector2 = (shore_target-position).normalized()
		if ability != null and ability.phase == "charge": ability.finish()
		var backing: bool = heading.dot(outward) < 0
		var escape_heading: float = outward.angle()+PI/2
		return Vector2(clampf(angle_difference(rotation,escape_heading)*2.4,-1,1),-1.0 if backing else 0.5)
	var blocked: bool = not nav.clear(position,position+heading*look,48)
	# Check the center plus both hull shoulders, using actual physics as well.
	for shoulder: float in [-34.0,0.0,34.0]:
		var start: Vector2 = position+Vector2.RIGHT.rotated(rotation)*shoulder
		blocked = blocked or not ray(start,start+heading*look,1).is_empty()
	if edge or blocked:
		if ability != null and ability.phase == "charge": ability.finish()
	elif ability != null and ability.phase == "charge":
		waypoints.clear()
		return Vector2(clampf(angle_difference(rotation,desired)*2.4,-1,1),throttle)
	# Resume the role's broadside tactics as soon as a clear firing lane is found.
	# Chasing the last route endpoint all the way to the target prevents alignment.
	if not edge and nav.clear(position,target.position) and position.distance_to(target.position) < tactics.ai_range*1.35:
		waypoints.clear()
		if not blocked: return Vector2(clampf(angle_difference(rotation,desired)*2.4,-1,1),throttle)
	if route_clock <= 0 and waypoints.is_empty() and (edge or blocked or not nav.clear(position,target.position)):
		waypoints = nav.route(position,Vector2.ZERO if edge else target.position)
		route_clock = 1.5
	while not waypoints.is_empty() and position.distance_to(waypoints[0]) < 80:
		if waypoints.size() > 1 and not nav.clear(position,waypoints[1],55): break
		waypoints.remove_at(0)
	if not waypoints.is_empty():
		desired = (waypoints[0]-position).angle()+PI/2
		var turn_error: float = absf(angle_difference(rotation,desired))
		# Keep turning toward the route while backing clear; never accelerate into
		# a tight corner before the bow points down the next leg.
		throttle = 0.85 if turn_error < 0.45 else (-1.0 if turn_error > 1.2 or blocked else 0.25)
	elif blocked:
		var best: float = -INF
		for angle: float in [-1.3,-0.7,0.7,1.3,PI]:
			var direction: Vector2 = heading.rotated(angle)
			var score: float = (2.0 if nav.clear(position,position+direction*220,48) else 0.0)-absf(angle)*0.1
			if signf(angle) == avoidance_side: score += 0.2
			if score > best:
				best = score
				desired = rotation+angle
				avoidance_side = signf(angle)
		throttle = 0.2
	if progress_clock >= 1.5:
		if position.distance_to(last_position) < 8 and get_slide_collision_count() > 0:
			recovery = 1.8
			waypoints = nav.route(position,nav.safe_point(position-heading*220+heading.orthogonal()*avoidance_side*180))
			avoidance_side *= -1
		last_position = position
		progress_clock = 0
	if recovery > 0:
		recovery -= delta
		return Vector2(avoidance_side,-1.0)
	return Vector2(clampf(angle_difference(rotation,desired)*2.4,-1,1),throttle)

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
