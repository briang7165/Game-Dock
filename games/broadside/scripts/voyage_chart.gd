extends Control
var state: Dictionary = {}
var travel: float = 0.0
const NAMES: Array[String] = ["The Sable Channel","Reefrunner Pass","Widowmaker Shoals","Blackwater Reach","Stormwatch Cay"]
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	custom_minimum_size = Vector2(0,180)
	resized.connect(queue_redraw)
func point(index: int) -> Vector2:
	var positions: Array[Vector2] = [Vector2(0.08,0.78),Vector2(0.28,0.12),Vector2(0.50,0.72),Vector2(0.72,0.08),Vector2(0.92,0.70)]
	return Vector2(65,30)+positions[index]*Vector2(size.x-130,maxf(35,size.y-120))
func harbor() -> Vector2: return Vector2(28,size.y-28)
func curve(from: Vector2,to: Vector2,t: float) -> Vector2:
	var first: Vector2 = from+Vector2((to.x-from.x)*0.65,0)
	var second: Vector2 = to-Vector2((to.x-from.x)*0.65,0)
	return from.bezier_interpolate(first,second,to,t)
func _draw() -> void:
	draw_style_box(chart_style(),Rect2(Vector2.ZERO,size))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(state.get("seed",1))+int(state.get("chapter",1))*31
	# Original ink-and-wash island clusters use the whole chart, not a horizontal ribbon.
	for i: int in range(30):
		var at := Vector2(rng.randf_range(25,size.x-25),rng.randf_range(25,size.y-25))
		var near_stop: bool = false
		for stop: int in range(5): near_stop = near_stop or at.distance_to(point(stop)+Vector2(0,20)) < 100
		if near_stop: continue
		var rock := PackedVector2Array()
		var radius: float = rng.randf_range(16,45)
		for angle: int in range(12): rock.append(at+Vector2.from_angle(angle*TAU/12)*radius*rng.randf_range(0.6,1.2))
		draw_colored_polygon(rock,Color("93a587"))
		draw_polyline(rock,Color("607d71"),3,true)
		var interior := PackedVector2Array()
		for vertex: Vector2 in rock: interior.append(at+(vertex-at)*0.65)
		draw_colored_polygon(interior,Color("778b65"))
	for i: int in range(40):
		var at := Vector2(rng.randf_range(15,size.x-15),rng.randf_range(20,size.y-20))
		draw_arc(at,12,0.3,2.8,9,Color("a5ae94"),1.2,true)
	var current: int = int(state.get("stop",0))
	for i: int in range(5):
		var begin: Vector2 = harbor() if i == 0 else point(i-1)
		for dot: int in range(45):
			draw_circle(curve(begin,point(i),dot/44.0),2.3,Color("537868") if i < current else Color("957955"))
	var font: Font = ThemeDB.fallback_font
	for i: int in range(5):
		var at: Vector2 = point(i)
		if i == current: draw_arc(at,25,0,TAU,48,Color("bc7b2d"),4,true)
		draw_circle(at,17,Color("497660") if i < current else (Color("874432") if i == 4 else Color("386c73")))
		draw_string(font,at+Vector2(-7,7),"✓" if i < current else str(i+1),HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("fff0c8"))
		var destination: Dictionary = state.duplicate(true)
		destination.stop = i
		var name: String = VoyageDirector.encounter(destination).location_name
		var split: int = name.rfind(" ")
		var lines: Array[String] = [name.left(split),name.substr(split+1)]
		for line: int in range(2):
			var width: float = font.get_string_size(lines[line],HORIZONTAL_ALIGNMENT_LEFT,-1,16).x
			draw_string(font,at+Vector2(-width/2,40+line*19),lines[line],HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("393b2d"))
		if i == 4: draw_string(font,at+Vector2(-23,-30),"BOSS",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("813f2c"))
	var begin: Vector2 = harbor() if current == 0 else point(current-1)
	var at: Vector2 = curve(begin,point(current),travel) if travel > 0 else begin
	draw_circle(at,21,Color("f6e7b9"))
	draw_colored_polygon(PackedVector2Array([at+Vector2(0,-19),at+Vector2(11,12),at+Vector2(-11,12)]),Color("69472f"))
	draw_line(at+Vector2(0,-17),at+Vector2(0,9),Color("403b2b"),2)
	draw_colored_polygon(PackedVector2Array([at+Vector2(1,-15),at+Vector2(16,2),at+Vector2(1,2)]),Color("fff8da"))
	var compass := Vector2(size.x-35,32)
	draw_arc(compass,18,0,TAU,32,Color("886d4c"),1,true)
	for i: int in range(4):
		var d := Vector2.from_angle(i*PI/2)
		draw_colored_polygon(PackedVector2Array([compass+d*23,compass+d.rotated(PI/2)*4,compass-d.rotated(PI/2)*4]),Color("69563e"))
func chart_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("d8c99c")
	style.border_color = Color("aa8951")
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	return style
