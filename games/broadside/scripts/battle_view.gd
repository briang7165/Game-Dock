extends VBoxContainer
## The world texture is clipped to the top slot; the footer is a sibling,
## never an overlay on world pixels. All sizes are logical canvas units.
var arena: Node2D
var battlefield: Control
var world: SubViewport
var hud: Control
var indicators: Control
var chrome: Control

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_theme_constant_override("separation",0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	battlefield = Control.new()
	battlefield.size_flags_vertical = Control.SIZE_EXPAND_FILL
	battlefield.mouse_filter = Control.MOUSE_FILTER_IGNORE
	battlefield.clip_contents = true
	add_child(battlefield)
	var container := SubViewportContainer.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.stretch = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	battlefield.add_child(container)
	world = SubViewport.new()
	world.size = Vector2i(1280,600)
	world.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	world.gui_disable_input = true
	container.add_child(world)
	world.add_child(arena)
	indicators = preload("res://scripts/enemy_indicators.gd").new()
	indicators.arena = arena
	battlefield.add_child(indicators)
	chrome = preload("res://scripts/location_title.gd").new()
	chrome.arena = arena
	battlefield.add_child(chrome)
	hud = preload("res://scripts/battle_hud.gd").new()
	hud.arena = arena
	hud.custom_minimum_size.y = hud.PANEL_HEIGHT
	add_child(hud)
