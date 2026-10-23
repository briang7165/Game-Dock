extends Control
var arena: Node2D
var title: Label
var subtitle: Label
var enemy_label: Label
var elapsed: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title = make_label(arena.encounter.location_name.to_upper(),24)
	title.position = Vector2(22,14)
	subtitle = make_label("—  " + arena.encounter.location_subtitle + "  —",16)
	subtitle.position = Vector2(22,45)
	enemy_label = make_label("",16)
	enemy_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	enemy_label.offset_left = -290
	enemy_label.offset_right = -20
	enemy_label.offset_top = 18
	enemy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_process(0)

func make_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",Color("e8dbb5"))
	label.add_theme_color_override("font_outline_color",Color("08232c"))
	label.add_theme_constant_override("outline_size",5)
	add_child(label)
	return label

func _process(delta: float) -> void:
	elapsed += delta
	var alpha: float = smoothstep(0,0.3,elapsed) * (1.0-smoothstep(2.0,2.8,elapsed))
	title.modulate.a = alpha
	subtitle.modulate.a = alpha
	enemy_label.text = "HOSTILE SLOOP   %d / %d HP" % [ceili(arena.enemy.health),arena.enemy.hull.max_health]
