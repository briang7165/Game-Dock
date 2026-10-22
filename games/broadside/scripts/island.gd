extends StaticBody2D
@export var radius: float = 80.0
var rim: PackedVector2Array

func _ready() -> void:
	collision_layer = 1
	collision_mask = 2
	for i: int in range(12):
		var angle: float = i * TAU / 12.0
		rim.append(Vector2.from_angle(angle) * radius * (0.9 + 0.1 * sin(i * 7.0)))
	var collision := CollisionPolygon2D.new()
	collision.polygon = rim
	add_child(collision)

func _draw() -> void:
	if rim.is_empty():
		return
	var foam := PackedVector2Array()
	for point: Vector2 in rim:
		foam.append(point * 1.16)
	draw_colored_polygon(foam, Color("386f76"))
	foam.append(foam[0])
	draw_polyline(foam, Color("85b6ad"), 3.0, true)
	draw_colored_polygon(rim, Color("494f50"))
	var inner := PackedVector2Array()
	for point: Vector2 in rim:
		inner.append(point * 0.78 + Vector2(-5,-7))
	draw_colored_polygon(inner, Color("899185"))
	for i: int in range(0, 12, 2):
		draw_colored_polygon(PackedVector2Array([Vector2(-10,-12),inner[i],inner[(i+1)%12]]),Color("a6aa91") if i % 4 == 0 else Color("687b71"))
	draw_circle(Vector2(-12,-15), radius * 0.22, Color("526b51"))
