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
var last_reward: int = 0
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
	var destination: EncounterStats = VoyageDirector.encounter(save.data)
	column.add_child(game.make_label("Next: "+destination.location_name+(" • "+destination.boss_name if not destination.boss_name.is_empty() else ""),20))
	status = game.make_label(save.error if not save.error.is_empty() else "Trade Winds: safer duels • Reef Passage: hazards / salvage • Blackwater: elite prizes",16)
	column.add_child(status)
	if save.data.active:
		button(column,"Resume interrupted encounter",start_travel.bind(int(save.data.route))).grab_focus()
	else:
		var routes := HBoxContainer.new()
		column.add_child(routes)
		for route: int in range(3):
			var option: Dictionary = save.data.duplicate(true)
			option.route = route
			var info: EncounterStats = VoyageDirector.encounter(option)
			var choice: Button = button(routes,"%s • %d foe%s • %d gold" % [VoyageDirector.ROUTES[route],info.enemy_roles.size(),"s" if info.enemy_roles.size() > 1 else "",VoyageDirector.reward(option)],start_travel.bind(route))
			choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			choice.tooltip_text = ["Safer duels, moderate gold. Always available after defeat.","More reefs; extra salvage and gold.","Elite hunters and later fleets; the greatest reward."][route]
			if route == 0: choice.grab_focus()
	button(column,"Safe harbor / Shipyard",show_harbor)
	button(column,"Voyage journal",show_journal)
	button(column,"Main menu",game.show_menu)

func start_travel(route: int = 0) -> void:
	if not save.begin_encounter(route):
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
		elif game.screen == "purchase":
			show_harbor()
		elif game.screen in ["journal","harbor"]:
			show_chart()
		elif game.screen in ["identity","chart","confirm_new","save_error"]:
			game.show_menu()
		get_viewport().set_input_as_handled()

func enter_battle() -> void:
	if not travelling:
		return
	travelling = false
	var encounter: EncounterStats = VoyageDirector.encounter(save.data)
	game.start_battle(encounter)
	in_battle = true
	Shipyard.apply(game.arena.player,save.data)
	game.arena.camera.zoom *= 1.0/(1+0.05*Shipyard.rank(save.data,"lookout")+(0.05 if save.data.get("crew","none") == "navigator" else 0))

func finish(victory: bool) -> void:
	in_battle = false
	var hp: float = game.arena.player.health
	var sunk: int = 0
	for hostile: BroadsideShip in game.arena.enemies:
		if hostile.dead: sunk += 1
	last_reward = VoyageDirector.reward(save.data) if victory else 0
	if not save.settle(victory,hp,sunk):
		get_tree().paused = true
		game.screen = "campaign_result"
		game.menu("Unable to save voyage",save.error,{"Retry save":func() -> void: finish(victory),"Main menu":game.show_menu})
		return
	reset_screen("campaign_result")
	game.audio.play_effect("victory" if victory else "defeat")
	game.menu("Victory at sea" if victory else "Rescued by harbor hands",identity()+"\n"+("Destination cleared. Earned %d gold and salvage. Hull %d. Your voyage continues." % [last_reward,int(save.data.health)] if victory else "Your captain and ship are safe. Emergency refit; retry this destination."),{"Safe harbor":show_harbor,"Chart of the Seas":show_chart,"Main menu":game.show_menu})

func retreat() -> void:
	finish(false)

func show_harbor() -> void:
	var column := reset_screen("harbor")
	column.add_child(game.make_label("Lantern Harbor — Shipyard",30))
	column.add_child(game.make_label(identity(),20))
	column.add_child(game.make_label("Gold %d  •  Salvage %d  •  Hull %d / %d" % [int(save.data.gold),int(save.data.get("salvage",0)),int(save.data.health),int(Shipyard.hull_for(save.data).max_health)],20))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(900,340)
	scroll.follow_focus = true
	column.add_child(scroll)
	var stock := VBoxContainer.new()
	stock.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(stock)
	button(stock,"Repair all hull — %d gold" % Shipyard.price(save.data,"repair",""),preview_purchase.bind("repair",""))
	button(stock,"Exchange salvage — 12 gold each",sell_salvage)
	for id: String in Shipyard.HULLS:
		button(stock,"%s — %d gold • %s" % [id.capitalize(),int(Shipyard.HULLS[id].price),Shipyard.HULLS[id].note],preview_purchase.bind("hull",id))
	for id: String in Shipyard.UPGRADES:
		button(stock,"%s [%d/%d] — %d gold" % [Shipyard.UPGRADES[id].name,Shipyard.rank(save.data,id),int(Shipyard.UPGRADES[id].max),Shipyard.price(save.data,"upgrade",id)],preview_purchase.bind("upgrade",id))
	for id: String in Shipyard.WEAPONS:
		button(stock,"%s guns — %d gold • %s" % [id.capitalize(),int(Shipyard.WEAPONS[id].price),Shipyard.WEAPONS[id].note],preview_purchase.bind("weapon",id))
	stock.add_child(game.make_label("Specialist berth • unlock after 3 victories • one active role",18))
	for id: String in VoyageDirector.CREW:
		button(stock, ("[Appointed] " if save.data.get("crew","none") == id else "")+VoyageDirector.CREW[id],appoint_crew.bind(id))
	status = game.make_label(save.error if not save.error.is_empty() else "Equipment transfers to your new hull; extra guns respect its port capacity.",16)
	column.add_child(status)
	button(column,"Chart next passage",show_chart).grab_focus()
	button(column,"Captain's papers",show_identity.bind(true))
	button(column,"Main menu",game.show_menu)

func preview_purchase(kind: String, id: String) -> void:
	var next: Dictionary = Shipyard.preview(save.data,kind,id)
	if next.is_empty():
		status.text = "Unavailable: insufficient gold, already fitted, maximum rank, or encounter in progress."
		return
	var before: HullStats = Shipyard.hull_for(save.data)
	var after: HullStats = Shipyard.hull_for(next)
	var guns: CannonStats = Shipyard.guns_for(next)
	var note: String = str(Shipyard.UPGRADES[id].note) if kind == "upgrade" else (str(Shipyard.HULLS[id].note) if kind == "hull" else "")
	reset_screen("purchase")
	game.menu("Shipwright's estimate", "%s\nCost %d gold • Remaining %d\nHull %d → %d • Speed %.0f → %.0f • Turn %.2f → %.2f\n%d guns per side • %.2fs reload • %.0f range\n%s" % [identity(),Shipyard.price(save.data,kind,id),int(next.gold),int(before.max_health),int(after.max_health),before.top_speed,after.top_speed,before.turn_rate,after.turn_rate,guns.gun_count,guns.reload_seconds,guns.projectile_speed*guns.projectile_lifetime,note],{"Back to shipyard":show_harbor,"Confirm purchase":func() -> void:
		Shipyard.purchase(save,kind,id)
		show_harbor()})

func sell_salvage() -> void:
	if save.data.active:
		status.text = "Finish the current encounter before trading."
		return
	var next: Dictionary = save.data.duplicate(true)
	next.gold = mini(1000000000,int(next.gold)+int(next.get("salvage",0))*12)
	next.salvage = 0
	save.commit(next)
	show_harbor()

func appoint_crew(id: String) -> void:
	if save.data.active or (int(save.data.wins) < 3 and id != "none"):
		status.text = "Finish your encounter and win 3 battles to appoint a specialist."
		return
	var next: Dictionary = save.data.duplicate(true)
	next.crew = id
	save.commit(next)
	show_harbor()

func show_journal() -> void:
	var column := reset_screen("journal")
	column.add_child(game.make_label("Captain's voyage journal",32))
	column.add_child(game.make_label(identity(),20))
	column.add_child(game.make_label("Title: %s • Chapter %d\n%d victories • %d ships sunk • %d rescues • %d flagships\n%d prize gold earned • Specialist: %s" % ["Stormrunner" if int(save.data.bosses) >= 3 else ("Reefbreaker" if int(save.data.bosses) > 0 else "New Horizons"),int(save.data.chapter),int(save.data.wins),int(save.data.get("ships_sunk",0)),int(save.data.losses),int(save.data.bosses),int(save.data.get("gold_earned",0)),str(save.data.get("crew","none")).capitalize()],20))
	for entry: String in save.data.get("journal",[]): column.add_child(game.make_label(entry,17))
	button(column,"Chart of the Seas",show_chart).grab_focus()
	button(column,"Safe harbor",show_harbor)
