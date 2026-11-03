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
	# Broken foam lanes and inward chevrons signal the broad current zone.
	for side: float in [-1.0,1.0]:
		for y: int in range(-720,721,120):
			var at := Vector2(side*1050,y)
			draw_polyline(PackedVector2Array([at+Vector2(side*16,-10),at,at+Vector2(side*16,10)]),Color(0.6,0.8,0.78,0.4),3,true)
		for x: int in range(-960,961,120):
			var at := Vector2(x,side*750)
			draw_polyline(PackedVector2Array([at+Vector2(-10,side*16),at,at+Vector2(10,side*16)]),Color(0.6,0.8,0.78,0.4),3,true)
	var weather: String = get_parent().encounter.weather
	if weather in ["rainy","stormy"]:
		for i: int in range(120 if weather == "stormy" else 65):
			var point := visible.position+Vector2(fposmod(i*137.3-time*80,visible.size.x),fposmod(i*97.7+time*380,visible.size.y))
			draw_line(point,point+Vector2(-6,18),Color(0.72,0.84,0.87,0.28),1.5,true)
	if weather in ["misty","stormy"]:
		for i: int in range(7):
			var y: float = visible.position.y+fposmod(i*167.0+time*8,visible.size.y)
			draw_line(Vector2(visible.position.x,y),Vector2(visible.end.x,y+45),Color(0.66,0.8,0.82,0.055),65,true)
	if weather in ["windy","stormy"]:
		for i: int in range(25):
			var at := visible.position+Vector2(fposmod(i*191.0+time*35,visible.size.x),fposmod(i*113.0,visible.size.y))
			draw_arc(at,28,0.3,2.4,8,Color(0.65,0.83,0.81,0.3),2,true)
