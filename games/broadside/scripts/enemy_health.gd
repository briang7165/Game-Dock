extends Control
## Screen-upright meters anchored above real world-space ships; never rotate with hulls.
var arena: Node2D
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
func _process(_delta: float) -> void: queue_redraw()
func meters() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not is_instance_valid(arena): return result
	for ship: BroadsideShip in arena.enemies:
		if ship.dead or not ship.is_visible_in_tree(): continue
		var at: Vector2 = ship.get_global_transform_with_canvas().origin
		if not Rect2(Vector2.ZERO,size).grow(-12).has_point(at): continue
		var boss: bool = ship.ability != null
		var width: float = 154 if boss else 94
		at.y -= 66*ship.hull_size.y*arena.camera.zoom.y+30
		at = at.clamp(Vector2(width/2+5,28),size-Vector2(width/2+5,20))
		# Lift overlapping labels in close fleet fights; hull orientation stays exposed.
		for prior: Dictionary in result:
			if absf(at.x-prior.at.x) < width and absf(at.y-prior.at.y) < 27: at.y = maxf(28,prior.at.y-30)
		result.append({"at":at,"width":width,"hp":ship.health,"max":ship.hull.max_health,"boss":boss,"name":arena.encounter.boss_name if boss else ""})
	return result
func _draw() -> void:
	var font: Font = ThemeDB.fallback_font
	for info: Dictionary in meters():
		var left: Vector2 = info.at-Vector2(info.width/2,0)
		draw_rect(Rect2(left-Vector2(2,2),Vector2(info.width+4,11)),Color("0a202a"))
		draw_rect(Rect2(left,Vector2(info.width,7)),Color("553c3b"))
		draw_rect(Rect2(left,Vector2(info.width*clampf(info.hp/maxf(1,info.max),0,1),7)),Color("e0b756") if info.boss else Color("ee9875"))
		var text: String = (info.name+"  " if info.boss else "")+"%d/%d" % [ceili(info.hp),ceili(info.max)]
		var pos: Vector2 = info.at+Vector2(-font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x/2,-5)
		draw_string_outline(font,pos,text,HORIZONTAL_ALIGNMENT_LEFT,-1,14,5,Color("0a202a"))
		draw_string(font,pos,text,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("fff0c8"))
