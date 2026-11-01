extends "res://scripts/readable_menu.gd"
var campaign: Node
var chart: Control
var status: Label
var sail_button: Button
var gold_label: Label
var navigation: HBoxContainer
func _ready() -> void:
	super._ready()
	var backdrop := ColorRect.new()
	backdrop.color = Color("0a222d")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var margins := MarginContainer.new()
	margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge: String in ["left","right","top","bottom"]: margins.add_theme_constant_override("margin_"+edge,10)
	add_child(margins)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",6)
	margins.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var title: Label = campaign.game.make_label("CHART OF THE SEAS • Chapter %d\n%s" % [campaign.save.data.chapter,campaign.identity()],20)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var purse := VBoxContainer.new()
	header.add_child(purse)
	gold_label = campaign.game.make_label("GOLD  %d" % int(campaign.save.data.gold),30)
	gold_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	purse.add_child(gold_label)
	var salvage: Label = campaign.game.make_label("%d salvage" % int(campaign.save.data.get("salvage",0)),18)
	salvage.autowrap_mode = TextServer.AUTOWRAP_OFF
	purse.add_child(salvage)
	chart = preload("res://scripts/voyage_chart.gd").new()
	chart.state = campaign.save.data
	chart.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(chart)
	var encounter: EncounterStats = VoyageDirector.encounter(campaign.save.data)
	status = campaign.game.make_label("NEXT • %d / 5 • %s\n%s" % [int(campaign.save.data.stop)+1,encounter.location_name,VoyageDirector.preview_text(campaign.save.data)],18)
	column.add_child(status)
	var advice: Label = campaign.game.make_label(VoyageDirector.preparation(campaign.save.data),16)
	column.add_child(advice)
	navigation = HBoxContainer.new()
	column.add_child(navigation)
	sail_button = campaign.button(navigation,("Resume " if campaign.save.data.active else "Set Sail to ")+encounter.location_name,campaign.start_travel)
	sail_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sail_button.size_flags_stretch_ratio = 2
	campaign.button(navigation,"Visit Harbor",campaign.show_harbor)
	campaign.button(navigation,"Journal",campaign.show_journal)
	campaign.button(navigation,"Main menu",campaign.game.show_menu)
	for control: Node in navigation.get_children():
		control.custom_minimum_size.y = 48
		control.add_theme_font_size_override("font_size",18)
	sail_button.grab_focus()
func begin_travel() -> void:
	for child: Node in navigation.get_children(): child.disabled = true
	sail_button.disabled = false
	sail_button.text = "Skip sailing • Enter / Space / Escape"
	sail_button.pressed.disconnect(campaign.start_travel)
	sail_button.pressed.connect(campaign.enter_battle)
	status.text = "Under way • Sailing to "+VoyageDirector.encounter(campaign.save.data).location_name
	sail_button.grab_focus()
