extends Control
signal closed
var audio: Node
var display: Node
var fullscreen_toggle: CheckButton
var music_slider: HSlider
var sfx_slider: HSlider
var music_mute: CheckButton
var sfx_mute: CheckButton

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color("071c26")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 470
	column.add_theme_constant_override("separation",16)
	center.add_child(column)
	var title := Label.new()
	title.text = "Sound & display"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size",30)
	column.add_child(title)
	music_slider = volume_row(column,"Music",audio.music_level,func(value: float) -> void: audio.music_level = value/100.0; audio.save_settings())
	music_mute = mute_row(column,"Mute music",audio.music_muted,func(value: bool) -> void: audio.music_muted = value; audio.save_settings())
	sfx_slider = volume_row(column,"Sound effects",audio.sfx_level,func(value: float) -> void: audio.sfx_level = value/100.0; audio.save_settings())
	sfx_mute = mute_row(column,"Mute sound effects",audio.sfx_muted,func(value: bool) -> void: audio.sfx_muted = value; audio.save_settings())
	fullscreen_toggle = mute_row(column,"Fullscreen (off: Windowed)",display.fullscreen,func(value: bool) -> void: display.set_fullscreen(value))
	var back := Button.new()
	back.text = "Back"
	back.custom_minimum_size.y = 44
	back.pressed.connect(func() -> void: audio.play_effect("select"); closed.emit())
	column.add_child(back)
	var help := Label.new()
	help.text = "W/S or ↑/↓ · Focus    A/D or ←/→ · Volume\nEnter/Space · Toggle    Escape · Back\nPreferences saved locally; no network required."
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(help)
	var controls: Array[Control] = [music_slider,music_mute,sfx_slider,sfx_mute,fullscreen_toggle,back]
	for i: int in range(controls.size()):
		controls[i].focus_neighbor_top = controls[i].get_path_to(controls[posmod(i-1,controls.size())])
		controls[i].focus_neighbor_bottom = controls[i].get_path_to(controls[(i+1)%controls.size()])
	music_slider.grab_focus()

func volume_row(column: VBoxContainer, caption: String, value: float, changed: Callable) -> HSlider:
	var label := Label.new()
	label.text = "%s   %d%%" % [caption,roundi(value*100)]
	label.add_theme_font_size_override("font_size",22)
	column.add_child(label)
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 5
	slider.value = value * 100
	slider.custom_minimum_size.y = 32
	slider.value_changed.connect(changed)
	slider.focus_entered.connect(func() -> void: label.add_theme_color_override("font_color",Color("ffd88a")))
	slider.focus_exited.connect(func() -> void: label.remove_theme_color_override("font_color"))
	slider.value_changed.connect(func(level: float) -> void: label.text = "%s   %d%%" % [caption,roundi(level)])
	column.add_child(slider)
	return slider

func mute_row(column: VBoxContainer, caption: String, value: bool, changed: Callable) -> CheckButton:
	var button := CheckButton.new()
	button.text = caption
	button.button_pressed = value
	button.custom_minimum_size.y = 36
	button.toggled.connect(changed)
	column.add_child(button)
	return button
