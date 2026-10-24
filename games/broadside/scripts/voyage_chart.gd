extends Control
var state: Dictionary = {}
var travel: float = 0.0
const NAMES: Array[String] = ["The Sable Channel","Reefrunner Pass","Widowmaker Shoals","Blackwater Reach","Stormwatch Cay"]

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(900,320)

func point(index: int) -> Vector2:
	return Vector2(90+index*(size.x-180)/4.0,160+sin(index*2.0)*60)

func _draw() -> void:
	draw_style_box(chart_style(),Rect2(Vector2.ZERO,size))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(state.get("seed",1))+int(state.get("chapter",1))*31
	for i: int in range(18):
		var at := Vector2(rng.randf_range(25,size.x-25),rng.randf_range(25,size.y-25))
		var rock := PackedVector2Array()
		for angle: int in range(8):
			rock.append(at+Vector2.from_angle(angle*TAU/8)*rng.randf_range(9,23))
		draw_colored_polygon(rock,Color("8b9872"))
		draw_polyline(rock,Color("66785e"),2,true)
	for i: int in range(4):
		for dot: int in range(20):
			draw_circle(point(i).lerp(point(i+1),dot/20.0),1.8,Color("886d4c"))
	var font: Font = ThemeDB.fallback_font
	for i: int in range(5):
		var at: Vector2 = point(i)
		draw_circle(at,12,Color("814735") if i == 4 else Color("386c73"))
		draw_circle(at,5,Color("edd9a8"))
		var label: String = NAMES[i] if i != 4 else "Stormwatch • BOSS"
		draw_string(font,at+Vector2(-65,35),label,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("403b2b"))
	var stop: int = int(state.get("stop",0))
	var at: Vector2 = point(maxi(0,stop-1)).lerp(point(stop),travel if travel > 0 else 1.0)
	if stop == 0 and travel > 0:
		at = Vector2(20,270).lerp(point(0),travel)
	draw_colored_polygon(PackedVector2Array([at+Vector2(0,-21),at+Vector2(12,12),at+Vector2(-12,12)]),Color("69472f"))
	draw_line(at+Vector2(0,-16),at+Vector2(0,8),Color("403b2b"),2)
	draw_colored_polygon(PackedVector2Array([at+Vector2(1,-15),at+Vector2(16,2),at+Vector2(1,2)]),Color("fff0c8"))
	# Original compass rose, chart-only illustration.
	var compass := Vector2(size.x-55,45)
	draw_arc(compass,22,0,TAU,32,Color("886d4c"),1,true)
	for i: int in range(4):
		var d := Vector2.from_angle(i*PI/2)
		draw_colored_polygon(PackedVector2Array([compass+d*27,compass+d.rotated(PI/2)*5,compass-d.rotated(PI/2)*5]),Color("69563e"))

func chart_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("d8c99c")
	style.border_color = Color("aa8951")
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	return style
