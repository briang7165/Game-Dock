extends Control
## Menus reflow at desktop pixel sizes; battlefield keeps its approved canvas scaling.
func _ready() -> void:
	get_viewport().size_changed.connect(fit)
	fit()
func fit() -> void:
	# A removed menu can receive resize before its deferred deletion.
	if not is_inside_tree(): return
	var factor: Vector2 = get_viewport().get_final_transform().get_scale()
	if DisplayServer.get_name() == "headless": factor = Vector2.ONE
	scale = Vector2.ONE/factor
	size = get_viewport_rect().size*factor
