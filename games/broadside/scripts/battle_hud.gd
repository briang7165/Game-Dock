extends Control
## Informational only. Each meter reads its own live battery; no input actions.
const PANEL_HEIGHT: float = 144.0
var arena: Node2D
var bottom: PanelContainer
var hull_bar: ProgressBar
var port_bar: ProgressBar
var starboard_bar: ProgressBar
var hull_label: Label
var hull_title: Label
var port_state: Label
var starboard_state: Label
var enemy_label: Label
var displayed_health: float
var previous_health: float
var flash: float = 0.0

func box(color: Color, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	return style

func label(text: String, font_size: int, color: Color = Color("e8dbb5")) -> Label:
	var result := Label.new()
	result.text = text
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.add_theme_font_size_override("font_size",font_size)
	result.add_theme_color_override("font_color",color)
	return result

func meter(column: VBoxContainer, color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size.y = 17
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background",box(Color("06151e"),Color("3c5157")))
	bar.add_theme_stylebox_override("fill",box(color))
	column.add_child(bar)
	return bar

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	displayed_health = arena.player.health
	previous_health = displayed_health
	bottom = PanelContainer.new()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 24
	bottom.offset_right = -24
	bottom.offset_top = -PANEL_HEIGHT-16
	bottom.offset_bottom = -16
	bottom.add_theme_stylebox_override("panel",box(Color("0a222df2"),Color("aa8951")))
	add_child(bottom)
	var margin := MarginContainer.new()
	for edge: String in ["left","right","top","bottom"]:
		margin.add_theme_constant_override("margin_"+edge,14)
	bottom.add_child(margin)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation",9)
	margin.add_child(stack)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",28)
	stack.add_child(row)
	var port := VBoxContainer.new()
	var hull := VBoxContainer.new()
	var starboard := VBoxContainer.new()
	for column: VBoxContainer in [port,hull,starboard]:
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.add_theme_constant_override("separation",5)
		row.add_child(column)
	hull.size_flags_stretch_ratio = 1.35
	port.add_child(label("◀  PORT CANNON",18))
	hull_title = label("HULL HEALTH",19)
	hull.add_child(hull_title)
	starboard.add_child(label("STARBOARD CANNON  ▶",18))
	port_bar = meter(port,Color("54bcae"))
	hull_bar = meter(hull,Color("c7b985"))
	starboard_bar = meter(starboard,Color("54bcae"))
	port_state = label("READY",19)
	hull_label = label("",21)
	starboard_state = label("READY",19)
	port.add_child(port_state)
	hull.add_child(hull_label)
	starboard.add_child(starboard_state)
	stack.add_child(label("WASD / ARROWS  Sail     •     SPACE  Fire loaded sides     •     ESC  Pause",14,Color("9eb1b3")))
	var enemy_panel := PanelContainer.new()
	enemy_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	enemy_panel.offset_left = -135
	enemy_panel.offset_right = 135
	enemy_panel.offset_top = 16
	enemy_panel.offset_bottom = 48
	enemy_panel.add_theme_stylebox_override("panel",box(Color("0a222de6"),Color("556569")))
	add_child(enemy_panel)
	enemy_label = label("",16,Color("e8c8b2"))
	enemy_panel.add_child(enemy_label)
	ignore_input(self)
	_process(0.0)

func ignore_input(node: Node) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node.focus_mode = Control.FOCUS_NONE
	for child: Node in node.get_children():
		ignore_input(child)

func battery_state(battery: CannonBattery, bar: ProgressBar, text: Label) -> void:
	var progress: float = clampf(1.0-battery.remaining/maxf(battery.stats.reload_seconds,0.001),0.0,1.0)
	bar.value = progress*100
	text.text = "READY" if battery.ready() else "%.1f s  •  %d%%" % [battery.remaining,roundi(progress*100)]
	var fill: StyleBoxFlat = bar.get_theme_stylebox("fill")
	fill.bg_color = Color("54bcae") if battery.ready() else Color("c4a568")

func _process(delta: float) -> void:
	if not is_instance_valid(arena):
		return
	var health: float = arena.player.health
	if health < previous_health:
		flash = 0.3
	previous_health = health
	flash = maxf(0.0,flash-delta)
	displayed_health = move_toward(displayed_health,health,arena.player.hull.max_health*1.6*delta)
	hull_bar.max_value = arena.player.hull.max_health
	hull_bar.value = displayed_health
	hull_label.text = "%d / %d HP" % [ceili(health),arena.player.hull.max_health]
	var critical: bool = health <= arena.player.hull.max_health*0.25
	hull_title.text = "!  HULL CRITICAL  !" if critical else "HULL HEALTH"
	var fill: StyleBoxFlat = hull_bar.get_theme_stylebox("fill")
	fill.bg_color = Color("ffe5a6") if flash > 0 else (Color("e69b66") if critical else Color("c7b985"))
	var panel_style: StyleBoxFlat = bottom.get_theme_stylebox("panel")
	panel_style.border_color = Color("fff1c4") if flash > 0 else Color("aa8951")
	battery_state(arena.player.port,port_bar,port_state)
	battery_state(arena.player.starboard,starboard_bar,starboard_state)
	enemy_label.text = "HOSTILE SLOOP   %d / %d HP" % [ceili(arena.enemy.health),arena.enemy.hull.max_health]
