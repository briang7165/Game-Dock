class_name SeaNavigation
extends RefCounted
## A small visibility graph around conservative island envelopes. Shared by all ships.
const CLEARANCE: float = 78.0
const INNER := Vector2(900,600) # Route points stay inside the AI's edge-return trigger.
var obstacles: Array[Dictionary] = []
var graph := AStar2D.new()
var count: int = 0

func build(rocks: Array[Dictionary]) -> void:
	obstacles = rocks
	graph.clear()
	count = 0
	for rock: Dictionary in obstacles:
		for i: int in range(12):
			var point: Vector2 = rock.center+Vector2.from_angle(i*TAU/12.0)*(float(rock.radius)+CLEARANCE+160)
			if absf(point.x) > INNER.x or absf(point.y) > INNER.y or not point_clear(point): continue
			graph.add_point(count,point)
			count += 1
	for a: int in range(count):
		for b: int in range(a):
			if clear(graph.get_point_position(a),graph.get_point_position(b)): graph.connect_points(a,b)

func point_clear(point: Vector2) -> bool:
	for rock: Dictionary in obstacles:
		if point.distance_to(rock.center) < float(rock.radius)+CLEARANCE: return false
	return true

func clear(a: Vector2, b: Vector2, margin: float = CLEARANCE) -> bool:
	for rock: Dictionary in obstacles:
		var nearest: Vector2 = Geometry2D.get_closest_point_to_segment(rock.center,a,b)
		if nearest.distance_to(rock.center) < float(rock.radius)+margin: return false
	return true

func safe_point(point: Vector2) -> Vector2:
	var result: Vector2 = point.clamp(-INNER,INNER)
	for pass_index: int in range(3):
		for rock: Dictionary in obstacles:
			var offset: Vector2 = result-rock.center
			var minimum: float = float(rock.radius)+CLEARANCE+10
			if offset.length() < minimum:
				result = rock.center+(offset.normalized() if offset.length() > 1 else Vector2.RIGHT)*minimum
	return result

func route(from: Vector2, destination: Vector2) -> PackedVector2Array:
	var start: Vector2 = safe_point(from)
	var goal: Vector2 = safe_point(destination)
	var result := PackedVector2Array()
	if from.distance_to(start) > 15: result.append(start)
	if clear(start,goal):
		result.append(goal)
		return result
	graph.add_point(count,start)
	graph.add_point(count+1,goal)
	for i: int in range(count):
		var point: Vector2 = graph.get_point_position(i)
		if clear(start,point): graph.connect_points(count,i)
		if clear(goal,point): graph.connect_points(count+1,i)
	var planned: PackedVector2Array = graph.get_point_path(count,count+1)
	graph.remove_point(count)
	graph.remove_point(count+1)
	for i: int in range(1,planned.size()): result.append(planned[i])
	return result

static func current(at: Vector2) -> Vector2:
	# Smooth water velocity, not a collision or a rotation override. Outward full
	# throttle is overcome before the camera's outer water zone; steering stays live.
	var depth: Vector2 = (at.abs()-Vector2(930,630))/Vector2(230,230)
	return Vector2(-signf(at.x)*pow(clampf(depth.x,0,1.5),2),-signf(at.y)*pow(clampf(depth.y,0,1.5),2))*420.0
