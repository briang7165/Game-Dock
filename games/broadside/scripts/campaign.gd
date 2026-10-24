extends Node
var game: Node
var save := CampaignSave.new()
var in_battle: bool = false
var travelling: bool = false
var travel_time: float = 0.0
var chart: Control
var captain_edit: LineEdit
var ship_edit: LineEdit
var pennant_choice: OptionButton
var status: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	save.load_game()

func reset_screen(screen_name: String) -> VBoxContainer:
	travelling = false
	get_tree().paused = false
	game.audio.set_battle(false)
	game.audio.ducked = true
	if is_instance_valid(game.arena):
		game.arena.get_parent().remove_child(game.arena)
		game.arena.queue_free()
		game.arena = null
	game.clear_ui()
	game.screen = screen_name
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game.ui.add_child(root)
	var shade := ColorRect.new()
	shade.color = Color("0a222d")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 900
	column.add_theme_constant_override("separation",10)
	center.add_child(column)
	game.panel = root
	return column

func button(column: Container, text: String, action: Callable) -> Button:
	var result := Button.new()
	result.text = text
	result.custom_minimum_size.y = 40
	result.pressed.connect(action)
	column.add_child(result)
	return result

func begin_new() -> void:
	if FileAccess.file_exists(save.path):
		reset_screen("confirm_new")
		game.menu("Start a new voyage?","This replaces your campaign. The previous safe save is backed up.",{"Keep current voyage":continue_game,"Replace voyage":show_identity})
	else:
		show_identity()

func show_identity(editing: bool = false) -> void:
	var column := reset_screen("identity")
	column.add_child(game.make_label("Captain's papers",32))
	column.add_child(game.make_label("Names are yours to choose. Leave blank for the story defaults.",18))
	column.add_child(game.make_label("Captain name",18))
	captain_edit = LineEdit.new()
	captain_edit.placeholder_text = "Captain Rowan"
	captain_edit.max_length = 28
	captain_edit.text = save.data.captain if editing else ""
	column.add_child(captain_edit)
	column.add_child(game.make_label("Ship name",18))
	ship_edit = LineEdit.new()
	ship_edit.placeholder_text = "The Wayfarer"
	ship_edit.max_length = 28
	ship_edit.text = save.data.ship if editing else ""
	column.add_child(ship_edit)
	pennant_choice = OptionButton.new()
	for color: String in ["Sea-glass pennant","Golden pennant","Ivory pennant"]:
		pennant_choice.add_item(color)
	pennant_choice.selected = int(save.data.pennant) if editing else 0
	column.add_child(pennant_choice)
	status = game.make_label("Tab moves between papers; Enter on Sign confirms. Escape returns.",16)
	column.add_child(status)
	button(column,"Sign the ship's papers",func() -> void:
		var next: Dictionary = save.data.duplicate(true) if editing else CampaignSave.fresh(captain_edit.text,ship_edit.text,pennant_choice.selected)
		next.captain = CampaignSave.clean_name(captain_edit.text,"Captain Rowan")
		next.ship = CampaignSave.clean_name(ship_edit.text,"The Wayfarer")
		next.pennant = pennant_choice.selected
		if save.commit(next):
			show_chart()
		else:
			status.text = save.error)
	button(column,"Back",show_harbor if editing else game.show_menu)
	captain_edit.grab_focus()

func continue_game() -> void:
	in_battle = false
	if save.load_game():
		show_chart()
	else:
		var column := reset_screen("save_error")
		column.add_child(game.make_label(save.error if not save.error.is_empty() else "No voyage saved yet.",18))
		button(column,"New voyage",begin_new).grab_focus()
		button(column,"Main menu",game.show_menu)

func identity() -> String:
	return "%s  •  %s  •  %s" % [save.data.captain,save.data.ship,str(save.data.hull).capitalize()]

func show_chart() -> void:
	in_battle = false
	var column := reset_screen("chart")
	column.add_child(game.make_label("Chart of the Seas — Chapter %d" % int(save.data.chapter),30))
	column.add_child(game.make_label(identity(),19))
	chart = preload("res://scripts/voyage_chart.gd").new()
	chart.state = save.data
	column.add_child(chart)
	column.add_child(game.make_label("Next: %s%s" % [chart.NAMES[int(save.data.stop)]," • Tidewarden's flagship" if int(save.data.stop) == 4 else ""],20))
	status = game.make_label(save.error if not save.error.is_empty() else "A safe harbor awaits after every encounter.",16)
	column.add_child(status)
	button(column,"Sail to destination" if not save.data.active else "Resume interrupted encounter",start_travel).grab_focus()
	button(column,"Safe harbor",show_harbor)
	button(column,"Main menu",game.show_menu)

func start_travel() -> void:
	if not save.begin_encounter():
		status.text = save.error
		return
	show_chart()
	travelling = true
	travel_time = 0
	game.screen = "travel"
	status.text = "Under way • Enter / Space / Escape to skip sailing"
	# Existing chart buttons become only a skip control during the interlude.
	var column: Node = chart.get_parent()
	for child: Node in column.get_children():
		if child is Button:
			column.remove_child(child)
			child.queue_free()
	button(column,"Skip sailing",enter_battle).grab_focus()

func _process(delta: float) -> void:
	if travelling:
		travel_time += delta
		chart.travel = clampf(travel_time/4.0,0.001,1)
		chart.queue_redraw()
		if travel_time >= 4:
			enter_battle()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		if travelling:
			enter_battle()
		elif game.screen in ["identity","chart","harbor","confirm_new","save_error"]:
			game.show_menu()
		get_viewport().set_input_as_handled()

func enter_battle() -> void:
	if not travelling:
		return
	travelling = false
	var encounter := EncounterStats.new()
	encounter.location_name = preload("res://scripts/voyage_chart.gd").NAMES[int(save.data.stop)]
	encounter.location_subtitle = "Chapter %d • %s" % [int(save.data.chapter),"Tidewarden's challenge" if int(save.data.stop) == 4 else "The voyage continues"]
	game.start_battle(encounter)
	in_battle = true
	game.arena.player.pennant = int(save.data.pennant)
	if int(save.data.stop) == 4:
		game.arena.enemy.hull = game.arena.enemy.hull.duplicate()
		game.arena.enemy.hull.max_health = 78
		game.arena.enemy.health = 78
		game.arena.enemy.tactics = game.arena.enemy.tactics.duplicate()
		game.arena.enemy.tactics.ai_telegraph = 1.2

func finish(victory: bool) -> void:
	in_battle = false
	var hp: float = game.arena.player.health
	if not save.settle(victory,hp):
		get_tree().paused = true
		game.screen = "campaign_result"
		game.menu("Unable to save voyage",save.error,{"Retry save":func() -> void: finish(victory),"Main menu":game.show_menu})
		return
	reset_screen("campaign_result")
	game.audio.play_effect("victory" if victory else "defeat")
	game.menu("Victory at sea" if victory else "Rescued by harbor hands",identity()+"\n"+("Destination cleared. Your voyage continues." if victory else "Your captain and ship are safe. Free refit; retry this destination."),{"Safe harbor":show_harbor,"Chart of the Seas":show_chart,"Main menu":game.show_menu})

func retreat() -> void:
	finish(false)

func show_harbor() -> void:
	var column := reset_screen("harbor")
	column.add_child(game.make_label("Lantern Harbor",32))
	column.add_child(game.make_label(identity(),20))
	column.add_child(game.make_label("Voyage journal • %d victories • %d rescues • %d bosses\nYour ship is refitted and ready. Shipyard trade opens in the next milestone." % [int(save.data.wins),int(save.data.losses),int(save.data.bosses)],18))
	button(column,"Chart next passage",show_chart).grab_focus()
	button(column,"Captain's papers",show_identity.bind(true))
	button(column,"Main menu",game.show_menu)
