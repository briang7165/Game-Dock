class_name UpgradeIcon
extends Control
var symbol: String = "cannons"
const INK := Color("d9bd7d")
func _ready() -> void: mouse_filter = Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
	draw_style_box(tile(),Rect2(Vector2.ZERO,size))
	draw_set_transform(size*0.5,0,Vector2.ONE*minf(size.x,size.y)/56.0)
	match symbol:
		"sails":
			draw_line(Vector2(0,-20),Vector2(0,19),INK,3,true)
			draw_colored_polygon(PackedVector2Array([Vector2(3,-18),Vector2(19,9),Vector2(3,8)]),INK)
			draw_line(Vector2(-18,16),Vector2(16,16),INK,4,true)
		"long":
			draw_line(Vector2(-21,8),Vector2(22,-13),INK,8,true)
			draw_circle(Vector2(-12,15),7,INK)
			draw_circle(Vector2(7,15),7,INK)
		"rudder":
			draw_arc(Vector2.ZERO,13,0,TAU,32,INK,3,true)
			for i: int in range(8):
				var ray := Vector2.UP.rotated(i*PI/4)*21
				draw_line(Vector2.ZERO,ray,INK,2,true)
		"armor","prow":
			for y: int in [-12,0,12]:
				draw_rect(Rect2(-18,y-4,36,8),INK)
			for x: int in [-12,12]:
				draw_line(Vector2(x,-19),Vector2(x,19),Color("65908f"),3,true)
		"carpenter","repair":
			draw_line(Vector2(-15,18),Vector2(13,-14),INK,5,true)
			draw_line(Vector2(-1,-18),Vector2(20,0),INK,9,true)
		"lookout":
			draw_line(Vector2(-16,13),Vector2(16,-12),INK,10,true)
			draw_circle(Vector2(16,-12),7,Color("70a7a3"))
		"cargo":
			draw_rect(Rect2(-20,-10,40,29),INK)
			draw_arc(Vector2(0,-10),20,PI,TAU,24,INK,4,true)
			draw_line(Vector2(-20,1),Vector2(20,1),Color("253d40"),3)
			draw_rect(Rect2(-3,-3,6,10),Color("253d40"))
		"chain":
			for x: int in [-10,10]: draw_arc(Vector2(x,0),12,0,TAU,32,INK,4,true)
		"gunners":
			draw_circle(Vector2(-10,9),9,INK)
			draw_circle(Vector2(10,9),9,INK)
			draw_circle(Vector2(0,-9),9,INK)
		_:
			draw_line(Vector2(-17,4),Vector2(17,-10),INK,12,true)
			draw_circle(Vector2(-11,13),7,INK)
			draw_circle(Vector2(10,13),7,INK)
static func tile() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("203b40")
	style.border_color = Color("8b794f")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	return style
