extends Node2D
var time: float = 0.0

func _process(delta: float) -> void:
	time += delta
	queue_redraw()

func _draw() -> void:
	# Cover the actual camera extent, including ultrawide views beyond fixed walls.
	var inverse: Transform2D = get_viewport().get_canvas_transform().affine_inverse()
	var visible := Rect2(inverse * Vector2.ZERO, Vector2.ZERO)
	visible = visible.expand(inverse * get_viewport_rect().size).grow(100)
	var theme: int = get_parent().encounter.theme
	draw_rect(visible,[Color("134655"),Color("243f4d"),Color("3b5961"),Color("223748")][theme])
	# Deterministic brush-like bands, no asset downloads or per-frame randomness.
	for row: int in range(floori(visible.position.y/83)-1,ceili(visible.end.y/83)+1):
		for col: int in range(floori(visible.position.x/90)-1,ceili(visible.end.x/90)+1):
			var x: float = col * 90.0 + sin(row * 13.0) * 32.0
			var y: float = row * 83.0 + sin(col * 3.0 + time * 0.4) * 8.0
			var tint := Color(0.16,0.46,0.50,0.20 + 0.10 * sin(row + col))
			draw_line(Vector2(x,y),Vector2(x+48,y-3),tint,9.0,true)
			draw_line(Vector2(x+9,y-5),Vector2(x+32,y-7),Color(0.52,0.76,0.73,0.18),1.5,true)
	draw_rect(Rect2(-1160,-860,2320,1720),Color("c2ad77"),false,4.0)
