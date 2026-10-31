extends Node
var settings_path: String = "user://display_settings.cfg"
var fullscreen: bool = false
var window_size := Vector2i(1280,720)
var window_position := Vector2i.ZERO

func _ready() -> void:
	get_window().min_size = Vector2i(800,450)
	load_settings()

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(settings_path) == OK:
		set_fullscreen(config.get_value("display","fullscreen",false) == true,false)

func set_fullscreen(enabled: bool, persist: bool = true) -> void:
	var window := get_window()
	if enabled and not fullscreen:
		window_size = window.size
		window_position = window.position
	fullscreen = enabled
	if DisplayServer.get_name() != "headless":
		window.mode = Window.MODE_FULLSCREEN if enabled else Window.MODE_WINDOWED
		if not enabled:
			window.size = window_size
			window.position = window_position
	if persist:
		var config := ConfigFile.new()
		config.set_value("display","fullscreen",fullscreen)
		config.save(settings_path)
