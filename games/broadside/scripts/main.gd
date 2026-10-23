extends Node
## The UI always processes; the entire combat subtree is pausable.
const Controls = preload("res://scripts/controls.gd")
var arena: Node2D
var ui: CanvasLayer
var hud: Control
var panel: Control
var screen: String = "menu"
var audio: Node
var settings_origin: String = "menu"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().auto_accept_quit = false
	Controls.install()
	audio = Node.new()
	audio.set_script(preload("res://scripts/audio.gd"))
	add_child(audio)
	ui = CanvasLayer.new()
	add_child(ui)
	show_menu()

func clear_ui() -> void:
	for child: Node in ui.get_children():
		ui.remove_child(child)
		child.queue_free()
	hud = null
	panel = null

func make_label(text: String, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color", Color("e8dbb5"))
	return label

func menu(title: String, subtitle: String, choices: Dictionary) -> void:
	panel = Control.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(panel)
	var shade := ColorRect.new()
	shade.color = Color(0.02,0.075,0.10,0.94)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",16)
	center.add_child(column)
	column.add_child(make_label("—  B R O A D S I D E  —",20))
	column.add_child(make_label(title,46))
	column.add_child(make_label(subtitle,18))
	var buttons: Array[Button] = []
	for caption: String in choices:
		var button := Button.new()
		button.text = caption
		button.custom_minimum_size = Vector2(330,48)
		button.add_theme_font_size_override("font_size",22)
		button.pressed.connect(audio.play_effect.bind("select"))
		button.pressed.connect(choices[caption])
		button.mouse_entered.connect(button.grab_focus)
		column.add_child(button)
		buttons.append(button)
	for index: int in range(buttons.size()):
		var previous: NodePath = buttons[index].get_path_to(buttons[posmod(index-1,buttons.size())])
		var next: NodePath = buttons[index].get_path_to(buttons[(index+1)%buttons.size()])
		buttons[index].focus_neighbor_top = previous
		buttons[index].focus_neighbor_left = previous
		buttons[index].focus_neighbor_bottom = next
		buttons[index].focus_neighbor_right = next
	buttons[0].grab_focus()
	column.add_child(make_label("WASD / arrows · Choose     Enter / Space · Select     Esc · Back",16))

func show_menu() -> void:
	get_tree().paused = false
	audio.clear_effects()
	audio.ducked = false
	audio.set_battle(false)
	if is_instance_valid(arena):
		remove_child(arena)
		arena.queue_free()
		arena = null
	clear_ui()
	screen = "menu"
	menu("The Sable Channel", "A one-on-one naval duel • M1.3 combat refinement\n\nW / ↑ throttle   S / ↓ brake & reverse   A D / ← → turn\nSpace fires BOTH loaded sides. Turn your hull to aim.\nReload is automatic. Escape pauses.", {"Set sail": start_battle,"Settings": show_settings,"Quit": quit_game})

func start_battle() -> void:
	get_tree().paused = false
	audio.clear_effects()
	audio.ducked = false
	audio.set_battle(true)
	if is_instance_valid(arena):
		remove_child(arena)
		arena.queue_free()
	clear_ui()
	screen = "battle"
	arena = preload("res://scenes/Arena.tscn").instantiate()
	arena.audio = audio
	arena.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(arena)
	arena.battle_ended.connect(end_battle)
	hud = Control.new()
	hud.set_script(preload("res://scripts/battle_hud.gd"))
	hud.arena = arena
	ui.add_child(hud)
	var indicators := Control.new()
	indicators.set_script(preload("res://scripts/enemy_indicators.gd"))
	indicators.arena = arena
	ui.add_child(indicators)

func _process(delta: float) -> void:
	audio.set_motion(absf(arena.player.speed)/arena.player.hull.top_speed if is_instance_valid(arena) else 0.0,delta)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not event.is_echo():
		if screen == "battle":
			pause_battle()
		elif screen == "pause":
			resume_battle()
		elif screen == "result":
			show_menu()
		elif screen == "settings":
			close_settings()
		get_viewport().set_input_as_handled()

func pause_battle() -> void:
	screen = "pause"
	get_tree().paused = true
	audio.ducked = true
	menu("Anchors held", "Combat is paused", {"Resume": resume_battle,"Settings": show_settings,"Restart duel": start_battle,"Main menu": show_menu})

func resume_battle() -> void:
	if is_instance_valid(panel):
		ui.remove_child(panel)
		panel.queue_free()
		panel = null
	screen = "battle"
	get_tree().paused = false
	audio.ducked = false

func end_battle(victory: bool) -> void:
	screen = "result"
	get_tree().paused = true
	audio.ducked = true
	audio.play_effect("victory" if victory else "defeat")
	menu("Victory" if victory else "Lost at sea", "Enemy sloop sunk. The channel is yours." if victory else "Your sloop has sunk. Try a wider firing angle.", {"Sail again": start_battle,"Main menu": show_menu})

func quit_game() -> void:
	audio.shutdown()
	# Let the audio mixer retire playback references before destroying the tree.
	await get_tree().create_timer(0.15,true,false,true).timeout
	get_tree().quit()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit_game()

func show_settings() -> void:
	settings_origin = screen
	if is_instance_valid(panel):
		ui.remove_child(panel)
		panel.queue_free()
	screen = "settings"
	panel = Control.new()
	panel.set_script(preload("res://scripts/audio_settings.gd"))
	panel.audio = audio
	ui.add_child(panel)
	panel.closed.connect(close_settings)

func close_settings() -> void:
	ui.remove_child(panel)
	panel.queue_free()
	panel = null
	if settings_origin == "pause":
		pause_battle()
	else:
		show_menu()
