class_name ShipyardUI
extends Control
## Stable two-column harbor: fixed repairs, independently scrolling stock and one checkout.
var campaign: Node
var selected: String = ""
var category: String = "Firepower"
var page_name: String = "Upgrades"
var scroll: ScrollContainer
var detail_scroll: ScrollContainer
var stock: VBoxContainer
var detail: VBoxContainer
var offer: Dictionary = {}
var confirm_button: Button
var cancel_button: Button
var repair_button: Button
var repair_bar: PanelContainer
var repair_label: Label
var health_bar: ProgressBar
var heading: Label
var active_art: ShipPortrait
var last_crew_button: Button
var fleet_buttons: Dictionary = {}
var upgrade_buttons: Dictionary = {}
var category_buttons: Dictionary = {}
var detail_title: Label
var detail_text: Label
var effect_text: Label
var price_text: Label
var advanced_text: Label
var detail_icon: UpgradeIcon
var numeric_button: CheckButton
var rename_edit: LineEdit
var current_kind: String = ""
var current_id: String = ""
var current_ship: String = ""
var stock_grid: GridContainer
var status: Label
const GOLD := Color("d5ba7e")
const PALE := Color("eadfc4")
func _ready() -> void:
	theme = harbor_theme()
	selected = campaign.save.data.hull
	build()
	get_viewport().size_changed.connect(fit_window)
	fit_window()
	if Shipyard.price(campaign.save.data,"repair","") > 0:
		repair_button.grab_focus()
		describe("repair","",false,campaign.save.data.hull)
	else: category_buttons[category].grab_focus()
func harbor_theme() -> Theme:
	var result := Theme.new()
	result.default_font_size = 16
	result.set_color("font_color","Label",PALE)
	for state: String in ["normal","hover","pressed","focus","disabled"]:
		var box: StyleBoxFlat = panel_style(Color("31494b") if state in ["hover","focus"] else Color("1b333a"))
		box.border_color = GOLD if state in ["hover","focus"] else Color("5a665b")
		result.set_stylebox(state,"Button",box)
	result.set_color("font_color","Button",PALE)
	return result
static func panel_style(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = Color("796b4e")
	box.set_border_width_all(1)
	box.set_corner_radius_all(5)
	box.content_margin_left = 10
	box.content_margin_right = 10
	box.content_margin_top = 6
	box.content_margin_bottom = 6
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
	result.custom_minimum_size.y = 32
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result.pressed.connect(action)
	parent.add_child(result)
	return result
func section(parent: Node, color: Color = Color("142d35")) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel",panel_style(color))
	parent.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",6)
	panel.add_child(box)
	return box
func fit_window() -> void:
	# Harbor uses physical-pixel layout on desktop, so 800px windows reflow instead of shrinking 1280px text.
	var factor: Vector2 = get_viewport().get_final_transform().get_scale()
	if DisplayServer.get_name() == "headless": factor = Vector2.ONE
	scale = Vector2.ONE/factor
	size = get_viewport_rect().size*factor
	if is_instance_valid(stock_grid): stock_grid.columns = 2 if size.x >= 1100 else 1
func build() -> void:
	var background := ColorRect.new()
	background.color = Color("0a202a")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margins := MarginContainer.new()
	margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge: String in ["left","right","top","bottom"]: margins.add_theme_constant_override("margin_"+edge,8)
	add_child(margins)
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation",6)
	margins.add_child(page)
	var header := HBoxContainer.new()
	page.add_child(header)
	active_art = ShipPortrait.new()
	active_art.vessel = campaign.save.data
	active_art.custom_minimum_size = Vector2(65,65)
	header.add_child(active_art)
	heading = label(header,"",18)
	var repair_box: VBoxContainer = section(page,Color("293a39"))
	repair_bar = repair_box.get_parent()
	repair_bar.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	repair_label = label(repair_box,"",15)
	var repair_row := HBoxContainer.new()
	repair_box.add_child(repair_row)
	health_bar = ProgressBar.new()
	health_bar.show_percentage = false
	health_bar.custom_minimum_size.x = 90
	health_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	repair_row.add_child(health_bar)
	repair_button = button(repair_row,"",inspect.bind("repair","","active"))
	button(repair_row,"Keep damage → Chart",campaign.show_chart)
	var navigation := HBoxContainer.new()
	page.add_child(navigation)
	for tab: String in ["Upgrades","Fleet","Crew"]:
		button(navigation,tab,show_page.bind(tab))
	button(navigation,"Voyage chart",campaign.show_chart)
	button(navigation,"Captain's papers",campaign.show_identity.bind(true))
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",10)
	page.add_child(body)
	var left: VBoxContainer = section(body)
	left.get_parent().size_flags_stretch_ratio = 1.25
	var tabs := GridContainer.new()
	tabs.columns = 2
	left.add_child(tabs)
	for cat: String in Shipyard.CATEGORIES:
		category_buttons[cat] = button(tabs,cat,show_category.bind(cat))
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(scroll)
	stock = VBoxContainer.new()
	stock.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(stock)
	var right: VBoxContainer = section(body,Color("303a37"))
	detail_scroll = ScrollContainer.new()
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_scroll.follow_focus = true
	right.add_child(detail_scroll)
	detail = VBoxContainer.new()
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.add_theme_constant_override("separation",8)
	detail_scroll.add_child(detail)
	var title_row := HBoxContainer.new()
	detail.add_child(title_row)
	detail_icon = UpgradeIcon.new()
	detail_icon.custom_minimum_size = Vector2(40,40)
	title_row.add_child(detail_icon)
	detail_title = label(title_row,"Choose a fitting",20)
	detail_title.modulate = GOLD
	detail_text = label(detail,"Hover or select a fitting to see what it does.")
	effect_text = label(detail,"",15)
	price_text = label(right,"",14)
	numeric_button = CheckButton.new()
	numeric_button.text = "Show numbers"
	numeric_button.toggled.connect(func(value: bool) -> void: advanced_text.visible = value)
	detail.add_child(numeric_button)
	advanced_text = label(detail,"",14)
	advanced_text.hide()
	var actions := HBoxContainer.new()
	right.add_child(actions)
	cancel_button = button(actions,"Cancel",cancel)
	confirm_button = button(actions,"Confirm purchase",confirm_offer)
	confirm_button.disabled = true
	status = label(page,"Only Confirm spends gold. Escape cancels. WASD / arrows and Enter work here.",14)
	campaign.status = status
	refresh(false)
func clear_stock() -> void:
	for child: Node in stock.get_children():
		stock.remove_child(child)
		child.queue_free()
	stock_grid = null
	fleet_buttons.clear()
	upgrade_buttons.clear()
func refresh(_focus_ship: bool = false) -> void:
	var old_scroll: int = scroll.scroll_vertical
	var focused: Control = get_viewport().gui_get_focus_owner()
	var focus_key: String = ""
	for key: String in upgrade_buttons:
		if upgrade_buttons[key] == focused: focus_key = key
	clear_stock()
	update_header()
	if page_name == "Fleet": build_fleet()
	elif page_name == "Crew": build_crew()
	else: build_upgrades()
	fit_window()
	if not focus_key.is_empty() and upgrade_buttons.has(focus_key): upgrade_buttons[focus_key].grab_focus()
	scroll.set_deferred("scroll_vertical",old_scroll)
func update_header() -> void:
	var data: Dictionary = campaign.save.data
	var hull: HullStats = Shipyard.hull_for(data)
	var guns: CannonStats = Shipyard.guns_for(data)
	heading.text = "LANTERN HARBOR • %s • %s / %s\n%d gold • %d salvage • %d cannons / side • %s" % [data.captain,data.ship,str(data.hull).capitalize(),int(data.gold),int(data.get("salvage",0)),guns.gun_count,Shipyard.capacity_text(data)]
	Shipyard.apply(active_art.preview_ship,data)
	var missing: int = ceili(maxf(0,hull.max_health-float(data.health)))
	repair_label.text = "%s: %d / %d HP • %d missing • %d gold to repair%s" % [data.ship,ceili(data.health),int(hull.max_health),missing,Shipyard.price(data,"repair","")," • Repair recommended" if missing > 0 else " • Ready to sail"]
	health_bar.max_value = hull.max_health
	health_bar.value = data.health
	repair_button.text = "Hull Ready" if missing == 0 else "Repair Active Ship — %d Gold" % Shipyard.price(data,"repair","")
	# Remains inspectable even when unaffordable, with a clear reason in checkout.
	repair_button.disabled = missing == 0
func show_page(tab: String) -> void:
	if not offer.is_empty(): status.text = "Confirm or cancel your estimate first."; return
	page_name = tab
	refresh()
func show_category(cat: String) -> void:
	if not offer.is_empty(): status.text = "Confirm or cancel your estimate first."; return
	category = cat
	page_name = "Upgrades"
	refresh()
func select_ship(id: String) -> void:
	if not offer.is_empty(): status.text = "Confirm or cancel your estimate first."; return
	selected = id
	refresh()
func build_upgrades() -> void:
	var select_row := HBoxContainer.new()
	stock.add_child(select_row)
	label(select_row,"Outfit ship:",15)
	var chooser := OptionButton.new()
	chooser.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ids: Array = campaign.save.data.fleet.keys()
	for id: String in ids: chooser.add_item(campaign.save.data.fleet[id].ship+" / "+id.capitalize())
	if not selected in ids: selected = campaign.save.data.hull
	chooser.selected = ids.find(selected)
	chooser.item_selected.connect(func(index: int) -> void: select_ship(ids[index]))
	select_row.add_child(chooser)
	stock_grid = GridContainer.new()
	stock_grid.columns = 2
	stock.add_child(stock_grid)
	for id: String in Shipyard.CATEGORIES[category]: upgrade_card(stock_grid,"upgrade",id)
	if category == "Firepower":
		for id: String in Shipyard.WEAPONS: upgrade_card(stock_grid,"weapon",id)
	if category == "Defense & Repairs": upgrade_card(stock_grid,"repair","")
func upgrade_card(parent: Node, kind: String, id: String) -> void:
	var state: Dictionary = FleetState.view(campaign.save.data,selected)
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(row)
	var icon := UpgradeIcon.new()
	icon.symbol = "repair" if kind == "repair" else id
	icon.custom_minimum_size = Vector2(32,42)
	row.add_child(icon)
	var tier: String = " • %d/%d" % [Shipyard.rank(state,id),Shipyard.tier_limit(state,id)] if kind == "upgrade" else ""
	var pick: Button = button(row,item_name(kind,id)+tier,inspect.bind(kind,id))
	pick.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pick.mouse_entered.connect(describe.bind(kind,id,false,""))
	pick.focus_entered.connect(describe.bind(kind,id,false,""))
	upgrade_buttons[kind+":"+id] = pick
func build_fleet() -> void:
	for id: String in Shipyard.HULLS:
		var state: Dictionary = FleetState.view(campaign.save.data,id)
		var row := HBoxContainer.new()
		stock.add_child(row)
		var art := ShipPortrait.new()
		art.vessel = state
		art.custom_minimum_size = Vector2(65,80)
		row.add_child(art)
		var owned: bool = campaign.save.data.fleet.has(id)
		var card := VBoxContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(card)
		label(card,"%s • %s" % [id.capitalize(),"ACTIVE" if id == campaign.save.data.hull else ("Owned" if owned else "%d gold" % int(Shipyard.HULLS[id].price))])
		fleet_buttons[id] = button(card,state.ship,func() -> void:
			if not offer.is_empty(): return
			selected = id
			show_ship(id))
	label(stock,"Selected ship: "+selected.capitalize(),17)
	if campaign.save.data.fleet.has(selected):
		rename_edit = LineEdit.new()
		rename_edit.text = campaign.save.data.fleet[selected].ship
		rename_edit.max_length = 28
		stock.add_child(rename_edit)
		button(stock,"Save ship name",func() -> void:
			if offer.is_empty(): Shipyard.rename_ship(campaign.save,selected,rename_edit.text); refresh())
		button(stock,"Make selected ship active",func() -> void:
			if offer.is_empty(): Shipyard.activate(campaign.save,selected); refresh())
		button(stock,"Repair selected owned ship",inspect.bind("repair",""))
	else: button(stock,"Purchase selected hull",inspect.bind("hull",selected))
func show_ship(id: String) -> void:
	refresh()
	var state: Dictionary = FleetState.view(campaign.save.data,id)
	var active: HullStats = Shipyard.hull_for(campaign.save.data)
	var hull: HullStats = Shipyard.hull_for(state)
	detail_title.text = state.ship+" / "+id.capitalize()
	detail_text.text = Shipyard.HULLS[id].note
	effect_text.text = "Active → selected: Hull %.0f → %.0f • Speed %.0f → %.0f • Turn %.2f → %.2f\nSelected condition %.0f / %.0f • %d guns per side\n%s" % [active.max_health,hull.max_health,active.top_speed,hull.top_speed,active.turn_rate,hull.turn_rate,state.health,hull.max_health,Shipyard.guns_for(state).gun_count,Shipyard.capacity_text(state)]
	price_text.text = "Your ships keep their own upgrades and damage."
	advanced_text.text = str(state.upgrades)
	confirm_button.disabled = true
func build_crew() -> void:
	label(stock,"One captain-wide specialist follows you between ships. Unlock after 3 wins.")
	for id: String in VoyageDirector.CREW:
		last_crew_button = button(stock,VoyageDirector.CREW[id],campaign.appoint_crew.bind(id))
	button(stock,"Trade all salvage for gold (12 each)",campaign.sell_salvage)
func item_name(kind: String, id: String) -> String:
	if kind == "upgrade": return Shipyard.UPGRADES[id].name
	if kind == "weapon": return Shipyard.WEAPONS[id].name
	if kind == "hull": return id.capitalize()+" hull"
	return "Ship Repairs"
func item_note(kind: String, id: String) -> String:
	if kind == "upgrade": return Shipyard.UPGRADES[id].note
	if kind == "weapon": return Shipyard.WEAPONS[id].note
	if kind == "hull": return Shipyard.HULLS[id].note+" Your other ships stay yours."
	return "Fix damage before the next fight, or keep your gold and sail damaged. Your choice."
func describe(kind: String, id: String, preparing: bool = false, vessel: String = "") -> void:
	if not offer.is_empty() and not preparing: return
	current_kind = kind
	current_id = id
	current_ship = selected if vessel.is_empty() else vessel
	var state: Dictionary = FleetState.view(campaign.save.data,current_ship)
	var availability: String = Shipyard.availability(campaign.save.data,kind,id,current_ship)
	detail_title.text = item_name(kind,id)
	detail_icon.symbol = "repair" if kind == "repair" else id
	detail_icon.queue_redraw()
	detail_text.text = item_note(kind,id)
	var cost: int = Shipyard.price(state,kind,id)
	var impact: String = ""
	if kind == "upgrade": impact = "Level %d → %d (limit %d)" % [Shipyard.rank(state,id),mini(Shipyard.rank(state,id)+1,Shipyard.tier_limit(state,id)),Shipyard.tier_limit(state,id)]
	elif kind == "repair": impact = "Health %.0f → %.0f" % [state.health,Shipyard.hull_for(state).max_health]
	elif kind == "weapon":
		var after: Dictionary = state.duplicate(true)
		after.weapon = id
		impact = "Hit damage %.0f → %.0f • Reload %.1fs → %.1fs" % [Shipyard.guns_for(state).damage,Shipyard.guns_for(after).damage,Shipyard.guns_for(state).reload_seconds,Shipyard.guns_for(after).reload_seconds]
	else: impact = "Adds one new ship; does not replace your active ship."
	effect_text.text = "%s • %s\n%s" % [state.ship,availability,impact]
	price_text.text = "%d gold • 0 salvage • %d gold left%s" % [cost,maxi(0,int(state.gold)-cost),"\nReady to buy? Confirm below." if preparing else "\nSelect the fitting to prepare an estimate."]
	var previous: String = selected
	selected = current_ship
	advanced_text.text = estimate_text(kind,id)
	selected = previous
	confirm_button.disabled = not preparing or availability != "Available"
func inspect(kind: String, id: String, target: String = "") -> void:
	if not offer.is_empty(): status.text = "Confirm or cancel the current estimate first."; return
	var vessel: String = campaign.save.data.hull if target == "active" else selected
	offer = Shipyard.quote(campaign.save.data,kind,id,vessel)
	describe(kind,id,true,vessel)
	status.text = "Estimate ready. Confirm spends gold; Cancel or Escape keeps your money."
	# No tooltip, overlay, reparenting, automatic focus change or scroll jump.
func cancel() -> void:
	offer.clear()
	confirm_button.disabled = true
	status.text = "Cancelled. Nothing was charged."
func confirm_offer() -> void:
	if offer.is_empty(): return
	var pending: Dictionary = offer.duplicate(true)
	offer.clear()
	confirm_button.disabled = true
	var success: bool = Shipyard.confirm(campaign.save,pending)
	refresh()
	describe(pending.kind,pending.id,false,pending.selected)
	status.text = "Done. Your ship is ready." if success else campaign.save.error
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo() and not offer.is_empty():
		cancel()
		get_viewport().set_input_as_handled()

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

