extends Control
## Awareness only: uses world positions, never touches weapons or steering.
var arena: Node2D
const EDGE: float = 38.0

static func marker(point: Vector2, viewport_size: Vector2) -> Dictionary:
	if Rect2(Vector2.ZERO, viewport_size).has_point(point):
		return {}
	var center: Vector2 = viewport_size * 0.5
	var direction: Vector2 = (point - center).normalized()
	var extent: Vector2 = center - Vector2(EDGE, EDGE)
	var factor: float = INF
	if absf(direction.x) > 0.0001:
		factor = minf(factor, extent.x / absf(direction.x))
	if absf(direction.y) > 0.0001:
		var vertical: float = center.y - 126.0 if direction.y < 0 else extent.y
		factor = minf(factor, vertical / absf(direction.y))
	return {"position": center + direction * factor, "direction": direction}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _process(_delta: float) -> void:
	queue_redraw()

func collect_markers() -> Array[Dictionary]:
	var markers: Array[Dictionary] = []
	if not is_instance_valid(arena) or arena.finished:
		return markers
	var occupied: Array[Vector2] = []
	# Deterministic cap and overlap suppression leave room for later fleets.
	for ship: BroadsideShip in get_tree().get_nodes_in_group("hostile_ships"):
		if ship.dead or not ship.is_visible_in_tree() or occupied.size() >= 4:
			continue
		var info: Dictionary = marker(ship.get_global_transform_with_canvas().origin, size)
		if info.is_empty():
			continue
		var point: Vector2 = info.position
		var overlaps: bool = false
		for used: Vector2 in occupied:
			overlaps = overlaps or used.distance_to(point) < 65.0
		if overlaps:
			continue
		occupied.append(point)
		info["distance"] = roundi(ship.global_position.distance_to(arena.player.global_position))
		markers.append(info)
	return markers

func _draw() -> void:
	for info: Dictionary in collect_markers():
		var point: Vector2 = info.position
		var direction: Vector2 = info.direction
		var normal := Vector2(-direction.y,direction.x)
		draw_circle(point,18,Color("122a32"))
		draw_colored_polygon(PackedVector2Array([point+direction*14,point-direction*9+normal*8,point-direction*5,point-direction*9-normal*8]),Color("ff9c78"))
		var text: String = "%d m" % info.distance
		var font: Font = ThemeDB.fallback_font
		var width: float = font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x
		var label_at: Vector2 = point - direction * 35.0 + Vector2(-width/2,5)
		draw_string_outline(font,label_at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,16,5,Color("102731"))
		draw_string(font,label_at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("ffe2c0"))
