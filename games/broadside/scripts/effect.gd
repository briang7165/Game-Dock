extends Node2D
var tint: Color = Color.WHITE
var radius: float = 18.0
var age: float = 0.0

func _process(delta: float) -> void:
	age += delta
	if age > 0.6:
		queue_free()
	queue_redraw()

func _draw() -> void:
	var fade: Color = tint
	fade.a = maxf(0, 1.0 - age / 0.6)
	draw_arc(Vector2.ZERO, 3.0 + radius * age * 2.0,0,TAU,24,fade,2.0,true)
	for i: int in range(5):
		draw_circle(Vector2.from_angle(i * TAU / 5.0) * age * radius, 2.0 + age * 5.0, fade)
