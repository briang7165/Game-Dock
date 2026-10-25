class_name ShipPortrait
extends Control
## Uses the actual battle renderer and battery data, with no movement or collision.
var vessel: Dictionary = {}
var preview_ship: BroadsideShip
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_ship = BroadsideShip.new()
	add_child(preview_ship)
	Shipyard.apply(preview_ship,vessel)
	preview_ship.collision_layer = 0
	preview_ship.collision_mask = 0
	preview_ship.process_mode = Node.PROCESS_MODE_DISABLED
	resized.connect(layout)
	layout()
func layout() -> void:
	if not is_instance_valid(preview_ship): return
	preview_ship.position = size*0.5
	preview_ship.rotation = -0.5
	preview_ship.scale = Vector2.ONE*minf(size.x/130.0,size.y/145.0)
	queue_redraw()
func _draw() -> void:
	var center: Vector2 = size*0.5
	var radius: float = minf(size.x,size.y)*0.43
	draw_circle(center,radius,Color("173b43"))
	for i: int in range(3):
		draw_arc(center,radius-i*7,0,TAU,64,Color(0.48,0.66,0.63,0.16),1,true)
	for i: int in range(8):
		var direction := Vector2.UP.rotated(i*PI/4)
		draw_line(center+direction*(radius-5),center+direction*(radius+3),Color("8b794f"),1,true)
