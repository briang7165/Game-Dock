class_name ShipyardUI
extends Control
var campaign: Node
var selected: String = ""
var category: String = "Firepower"
var scroll: ScrollContainer
var content: VBoxContainer
var detail: VBoxContainer
var offer: Dictionary = {}
var confirm_button: Button
var cancel_button: Button
var last_crew_button: Button
var fleet_buttons: Dictionary = {}
var upgrade_buttons: Dictionary = {}
var detail_title: Label
var detail_text: Label
var modal: Control
var rename_edit: LineEdit
const GOLD := Color("d5ba7e")
const PALE := Color("eadfc4")
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = harbor_theme()
	selected = campaign.save.data.hull
	refresh()
func harbor_theme() -> Theme:
	var result := Theme.new()
	result.default_font_size = 16
	result.set_color("font_color","Label",PALE)
	for state: String in ["normal","hover","pressed","focus","disabled"]:
		var box: StyleBoxFlat = panel_style(Color("31494b") if state in ["hover","focus"] else Color("1b333a"))
		box.border_color = GOLD if state in ["hover","focus"] else Color("5a665b")
		result.set_stylebox(state,"Button",box)
	result.set_color("font_color","Button",PALE)
	result.set_color("font_hover_color","Button",Color.WHITE)
	return result
static func panel_style(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = Color("796b4e")
	box.set_border_width_all(1)
	box.set_corner_radius_all(7)
	box.content_margin_left = 14
	box.content_margin_right = 14
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	return box
func label(parent: Node, text: String, font_size: int = 16) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_size_override("font_size",font_size)
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(result)
	return result
func button(parent: Node, title: String, action: Callable) -> Button:
	var result := Button.new()
	result.text = title
	result.custom_minimum_size.y = 36
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result.pressed.connect(action)
	parent.add_child(result)
	return result
func section(parent: Node, width: float, color: Color = Color("142d35")) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = width
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel",panel_style(color))
	parent.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",9)
	panel.add_child(box)
	return box
func portrait(parent: Node, state: Dictionary, dimensions: Vector2) -> ShipPortrait:
	var art := ShipPortrait.new()
	art.vessel = state
	art.custom_minimum_size = dimensions
	art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(art)
	return art
func refresh(focus_ship: bool = true) -> void:
	offer.clear()
	fleet_buttons.clear()
	upgrade_buttons.clear()
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	var background := ColorRect.new()
	background.color = Color("0a202a")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margins := MarginContainer.new()
	margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge: String in ["left","right","top","bottom"]: margins.add_theme_constant_override("margin_"+edge,14)
	add_child(margins)
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation",10)
	margins.add_child(page)
	var heading := HBoxContainer.new()
	page.add_child(heading)
	label(heading,"LANTERN HARBOR  /  THE SHIPWRIGHT",26).modulate = GOLD
	var purse: Label = label(heading,"%d gold   •   %d salvage" % [int(campaign.save.data.gold),int(campaign.save.data.get("salvage",0))],21)
	purse.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	active_header(page)
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.follow_focus = true
	page.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation",12)
	scroll.add_child(content)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation",12)
	content.add_child(body)
	gallery(section(body,235,Color("382f29")))
	comparison(section(body,355,Color("cbb88d")))
	upgrades(section(body,535,Color("303a37")))
	campaign.status = label(page,campaign.save.error if not campaign.save.error.is_empty() else "Select a ship, then inspect its fittings. Only Confirm spends gold.  •  WASD / arrows navigate; Enter / Space select.",14)
	var navigation := HBoxContainer.new()
	page.add_child(navigation)
	button(navigation,"← Voyage chart",campaign.show_chart)
	button(navigation,"Captain's papers",campaign.show_identity.bind(true))
	button(navigation,"Exchange salvage • 12 gold each",campaign.sell_salvage)
	button(navigation,"Main menu",campaign.game.show_menu)
	if focus_ship: fleet_buttons[selected].grab_focus()
func active_header(parent: Node) -> void:
	var box: VBoxContainer = section(parent,0,Color("293a39"))
	var row := HBoxContainer.new()
	box.add_child(row)
	var state: Dictionary = campaign.save.data
	portrait(row,state,Vector2(140,125)).size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	label(text,"ACTIVE VESSEL  •  Captain "+state.captain,15).modulate = GOLD
	label(text,"%s  /  %s" % [state.ship,str(state.hull).capitalize()],27)
	var hull: HullStats = Shipyard.hull_for(state)
	var guns: CannonStats = Shipyard.guns_for(state)
	label(text,"Hull %.0f / %.0f   •   %d cannons per side   •   %.2fs reload   •   Speed %.0f   •   Turn %.2f" % [state.health,hull.max_health,guns.gun_count,guns.reload_seconds,hull.top_speed,hull.turn_rate],18)
	label(text,"Armor %d   •   %s weapons   •   %s   •   Captain-wide specialist: %s" % [Shipyard.rank(state,"armor"),str(state.weapon).capitalize(),Shipyard.capacity_text(state),str(state.get("crew","none")).capitalize()],16)
func gallery(box: VBoxContainer) -> void:
	label(box,"YOUR FLEET",20).modulate = GOLD
	label(box,"Inspect any hull. Owned vessels stay yours.",14)
	for id: String in Shipyard.HULLS:
		var state: Dictionary = FleetState.view(campaign.save.data,id)
		var owned: bool = campaign.save.data.fleet.has(id)
		var card := VBoxContainer.new()
		box.add_child(card)
		var row := HBoxContainer.new()
		card.add_child(row)
		portrait(row,state,Vector2(78,96)).size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		var titles := VBoxContainer.new()
		titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(titles)
		label(titles,id.capitalize(),21)
		label(titles,state.ship,14)
		label(titles,"ACTIVE" if id == campaign.save.data.hull else ("OWNED" if owned else "AVAILABLE • %d gold" % int(Shipyard.HULLS[id].price)),14).modulate = GOLD
		label(card,"HP %.0f → %.0f  •  Guns %d → %d\n%s" % [Shipyard.HULLS[id].hp,Shipyard.hull_for(state).max_health,int(Shipyard.HULLS[id].guns),Shipyard.guns_for(state).gun_count,Shipyard.capacity_text(state)],14)
		var pick: Button = button(card,("◆ " if id == selected else "")+"Inspect "+id.capitalize(),select_ship.bind(id))
		fleet_buttons[id] = pick
func select_ship(id: String) -> void:
	selected = id
	refresh()
func comparison(box: VBoxContainer) -> void:
	box.theme = theme.duplicate(true)
	box.theme.set_color("font_color","Label",Color("273b40"))
	var data: Dictionary = campaign.save.data
	var state: Dictionary = FleetState.view(data,selected)
	label(box,"SHIP'S PAPERS",20).modulate = GOLD
	portrait(box,state,Vector2(240,195))
	label(box,state.ship,24)
	label(box,Shipyard.HULLS[selected].note,15)
	if data.fleet.has(selected):
		var row := HBoxContainer.new()
		box.add_child(row)
		rename_edit = LineEdit.new()
		rename_edit.text = state.ship
		rename_edit.max_length = 28
		rename_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(rename_edit)
		button(row,"Name",func() -> void:
			Shipyard.rename_ship(campaign.save,selected,rename_edit.text)
			refresh())
		var activate: Button = button(box,"Currently active" if selected == data.hull else "Make active • no cost",func() -> void:
			Shipyard.activate(campaign.save,selected)
			refresh())
		activate.disabled = selected == data.hull or data.active
	else:
		button(box,"Purchase hull • %d gold" % int(Shipyard.HULLS[selected].price),inspect.bind("hull",selected))
	label(box,"ACTIVE  /  SELECTED  /  CHANGE",14).modulate = GOLD
	var a: HullStats = Shipyard.hull_for(data)
	var b: HullStats = Shipyard.hull_for(state)
	var ag: CannonStats = Shipyard.guns_for(data)
	var bg: CannonStats = Shipyard.guns_for(state)
	stat(box,"Hull",a.max_health,b.max_health,280)
	stat(box,"Guns / side",ag.gun_count,bg.gun_count,6)
	stat(box,"Reload (s)",ag.reload_seconds,bg.reload_seconds,4,true)
	stat(box,"Speed",a.top_speed,b.top_speed,230)
	stat(box,"Turn",a.turn_rate,b.turn_rate,1.1)
	stat(box,"Armor tier",Shipyard.rank(data,"armor"),Shipyard.rank(state,"armor"),3)
	label(box,"Selected base → installed\nHull %.0f → %.0f • Speed %.0f → %.0f\nTurn %.2f → %.2f • Guns %d → %d" % [Shipyard.HULLS[selected].hp,b.max_health,Shipyard.HULLS[selected].speed,b.top_speed,Shipyard.HULLS[selected].turn,b.turn_rate,int(Shipyard.HULLS[selected].guns),bg.gun_count],14)
	label(box,"Potential (not installed): %.0f HP • %d guns/side\nArmor limit %d • Rudder limit %d • Sails limit %d\nSlots limit combinations; legacy purchases are retained." % [float(Shipyard.HULLS[selected].hp)+18*Shipyard.tier_limit(state,"armor"),int(Shipyard.HULLS[selected].capacity),Shipyard.tier_limit(state,"armor"),Shipyard.tier_limit(state,"rudder"),Shipyard.tier_limit(state,"sails")],14).modulate = GOLD
	for cat: String in Shipyard.CATEGORIES:
		label(box,"%s: %d / %d slots" % [cat,Shipyard.used(state,cat),Shipyard.slots(state,cat)],14)
	var installed: PackedStringArray = []
	for id: String in Shipyard.UPGRADES:
		if Shipyard.rank(state,id) > 0: installed.append("%s %d/%d" % [Shipyard.UPGRADES[id].name,Shipyard.rank(state,id),Shipyard.tier_limit(state,id)])
	label(box,"Installed: "+("None" if installed.is_empty() else ", ".join(installed)),14)
func stat(parent: Node, title: String, active: float, value: float, maximum: float, lower_better: bool = false) -> void:
	var change: float = value-active
	var row: Label = label(parent,"%s   %.2f  /  %.2f  (%+.2f)" % [title,active,value,change],14)
	if absf(change) > 0.001: row.modulate = Color("8ed6ae") if (change < 0 if lower_better else change > 0) else Color("eea08c")
	var bar := ProgressBar.new()
	bar.max_value = maximum
	bar.value = value
	bar.show_percentage = false
	bar.custom_minimum_size.y = 6
	parent.add_child(bar)
func upgrades(box: VBoxContainer) -> void:
	label(box,"OUTFIT  /  "+selected.to_upper(),20).modulate = GOLD
	var tabs := GridContainer.new()
	tabs.columns = 2
	box.add_child(tabs)
	for cat: String in Shipyard.CATEGORIES:
		button(tabs,("◆ " if cat == category else "")+cat,func() -> void:
			category = cat
			refresh(false)
			upgrade_buttons.values()[0].grab_focus())
	var stock := GridContainer.new()
	stock.columns = 2
	stock.add_theme_constant_override("h_separation",8)
	stock.add_theme_constant_override("v_separation",8)
	box.add_child(stock)
	for id: String in Shipyard.CATEGORIES[category]: upgrade_card(stock,"upgrade",id)
	if category == "Firepower":
		for id: String in Shipyard.WEAPONS: upgrade_card(stock,"weapon",id)
	if category == "Defense & Repairs": upgrade_card(stock,"repair","")
	detail = section(box,0,Color("3d443b"))
	detail_title = label(detail,"SHIPWRIGHT'S ESTIMATE",21)
	detail_title.modulate = GOLD
	detail_text = label(detail,"Hover or focus a fitting to read its effects. Select to prepare a purchase; Confirm is a separate action.",16)
	var actions := HBoxContainer.new()
	detail.add_child(actions)
	cancel_button = button(actions,"Cancel",cancel)
	confirm_button = button(actions,"Confirm",confirm_offer)
	confirm_button.disabled = true
	label(box,"CAPTAIN-WIDE SPECIALIST",16).modulate = GOLD
	label(box,"One shared berth, unlocked after 3 victories. Follows your captain between ships.",14)
	for id: String in VoyageDirector.CREW:
		last_crew_button = button(box,("◆ " if campaign.save.data.get("crew","none") == id else "")+VoyageDirector.CREW[id],campaign.appoint_crew.bind(id))
func upgrade_card(parent: Node, kind: String, id: String) -> void:
	var state: Dictionary = FleetState.view(campaign.save.data,selected)
	var card := VBoxContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(card)
	var row := HBoxContainer.new()
	card.add_child(row)
	var icon := UpgradeIcon.new()
	icon.symbol = id if kind != "repair" else "repair"
	icon.custom_minimum_size = Vector2(44,44)
	row.add_child(icon)
	var title: String = item_name(kind,id)
	label(row,title,15)
	var tier: String = "%d / %d" % [Shipyard.rank(state,id),Shipyard.tier_limit(state,id)] if kind == "upgrade" else ("Equipped" if kind == "weapon" and state.weapon == id else "Loadout")
	var pick: Button = button(card,"%s • %d gold" % [tier,Shipyard.price(state,kind,id)],inspect.bind(kind,id))
	pick.tooltip_text = estimate_text(kind,id)
	pick.mouse_entered.connect(describe.bind(kind,id,false))
	pick.focus_entered.connect(describe.bind(kind,id,false))
	upgrade_buttons[kind+":"+id] = pick
func item_name(kind: String, id: String) -> String:
	if kind == "upgrade": return Shipyard.UPGRADES[id].name
	if kind == "weapon": return id.capitalize()+" weapons"
	if kind == "hull": return id.capitalize()+" hull"
	return "Repair hull"
func item_note(kind: String, id: String) -> String:
	if kind == "upgrade": return Shipyard.UPGRADES[id].note
	if kind == "weapon": return Shipyard.WEAPONS[id].note
	if kind == "hull": return Shipyard.HULLS[id].note+" Adds a new vessel; keeps your active ship and its equipment."
	return "Restore this vessel's missing hull. Costs one gold per two HP, rounded up."
func describe(kind: String, id: String, preparing: bool) -> void:
	if not is_instance_valid(detail_text) or (not offer.is_empty() and not preparing): return
	detail_title.text = item_name(kind,id)+(" • CONFIRM?" if preparing else "")
	detail_text.text = estimate_text(kind,id)
	confirm_button.disabled = not preparing or Shipyard.preview(campaign.save.data,kind,id,selected).is_empty()
func estimate_text(kind: String, id: String) -> String:
	var state: Dictionary = FleetState.view(campaign.save.data,selected)
	var available: String = Shipyard.availability(campaign.save.data,kind,id,selected)
	# Show the numerical effect even when gold is insufficient; authorization still uses the real save.
	var simulation: Dictionary = state.duplicate(true)
	simulation.gold = 1000000000
	simulation.active = false
	var proposed: Dictionary = Shipyard.preview(simulation,kind,id,selected)
	var after: Dictionary = FleetState.view(proposed,selected) if not proposed.is_empty() else state
	var a: HullStats = Shipyard.hull_for(state)
	var b: HullStats = Shipyard.hull_for(after)
	var ga: CannonStats = Shipyard.guns_for(state)
	var gb: CannonStats = Shipyard.guns_for(after)
	var cost: int = Shipyard.price(state,kind,id)
	var tier: String = "Tier %d → %d / %d\n" % [Shipyard.rank(state,id),Shipyard.rank(after,id),Shipyard.tier_limit(state,id)] if kind == "upgrade" else ""
	var extra: String = ""
	match id:
		"sails": extra = "Acceleration %.1f → %.1f\n" % [a.acceleration,b.acceleration]
		"rudder": extra = "Helm response %.2f → %.2f\n" % [a.rudder_acceleration,b.rudder_acceleration]
		"lookout": extra = "Extra sea visible %.0f%% → %.0f%%\n" % [5*Shipyard.rank(state,id),5*Shipyard.rank(after,id)]
		"cargo": extra = "Bonus prize gold %.0f%% → %.0f%% • Extra salvage %d → %d\n" % [20*Shipyard.rank(state,id),20*Shipyard.rank(after,id),Shipyard.rank(state,id),Shipyard.rank(after,id)]
		"carpenter": extra = "Victory repairs %d → %d HP\n" % [5*Shipyard.rank(state,id),5*Shipyard.rank(after,id)]
		"prow": extra = "Ram bonus %.0f%% → %.0f%% • Impact protection %.0f%% → %.0f%%\n" % [20*Shipyard.rank(state,id),20*Shipyard.rank(after,id),15*Shipyard.rank(state,id),15*Shipyard.rank(after,id)]
	return "%s • %s\n%s\n%s%s\nCondition %.0f → %.0f • Maximum hull %.0f → %.0f\nGuns / side %d → %d • Damage %.0f → %.0f\nReload %.2fs → %.2fs • Speed %.0f → %.0f\nTurn %.2f → %.2f • Range %.0f → %.0f\n%sCost %d gold / 0 salvage • Remaining %d gold" % [state.ship,selected.capitalize(),item_note(kind,id),tier,available,state.health,after.health,a.max_health,b.max_health,ga.gun_count,gb.gun_count,ga.damage,gb.damage,ga.reload_seconds,gb.reload_seconds,a.top_speed,b.top_speed,a.turn_rate,b.turn_rate,ga.projectile_speed*ga.projectile_lifetime,gb.projectile_speed*gb.projectile_lifetime,extra,cost,maxi(0,int(state.gold)-cost)]

func inspect(kind: String, id: String) -> void:
	offer = Shipyard.quote(campaign.save.data,kind,id,selected)
	describe(kind,id,true)
	# Modal estimate traps keyboard focus and blocks clicks through to the harbor.
	for control: Node in find_children("*","Control",true,false):
		if control is Button or control is LineEdit: control.focus_mode = Control.FOCUS_NONE
	modal = Control.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(modal)
	var shade := ColorRect.new()
	shade.color = Color(0.02,0.07,0.09,0.9)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(center)
	var panel: Control = detail.get_parent()
	panel.reparent(center)
	panel.custom_minimum_size.x = 720
	var icon := UpgradeIcon.new()
	icon.symbol = "repair" if kind == "repair" else id
	icon.custom_minimum_size = Vector2(64,64)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	detail.add_child(icon)
	detail.move_child(icon,1)
	cancel_button.focus_mode = Control.FOCUS_ALL
	confirm_button.focus_mode = Control.FOCUS_ALL
	cancel_button.focus_neighbor_right = cancel_button.get_path_to(confirm_button)
	confirm_button.focus_neighbor_left = confirm_button.get_path_to(cancel_button)
	cancel_button.grab_focus()
func cancel() -> void:
	offer.clear()
	refresh()
	campaign.status.text = "Estimate cancelled. Nothing was charged."
func confirm_offer() -> void:
	if offer.is_empty(): return
	var pending: Dictionary = offer.duplicate(true)
	offer.clear()
	confirm_button.disabled = true
	Shipyard.confirm(campaign.save,pending)
	refresh()
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo() and not offer.is_empty():
		cancel()
		get_viewport().set_input_as_handled()
