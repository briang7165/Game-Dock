extends RefCounted
## Add physical keys at boot so keyboard layouts and menus share one contract.
static func install() -> void:
	var bindings: Dictionary = {
		"throttle": [KEY_W, KEY_UP], "brake": [KEY_S, KEY_DOWN],
		"port": [KEY_A, KEY_LEFT], "starboard": [KEY_D, KEY_RIGHT],
		"fire": [KEY_SPACE], "pause": [KEY_ESCAPE],
		"ui_up": [KEY_W, KEY_UP], "ui_down": [KEY_S, KEY_DOWN],
		"ui_left": [KEY_A, KEY_LEFT], "ui_right": [KEY_D, KEY_RIGHT],
		"ui_accept": [KEY_ENTER, KEY_SPACE], "ui_cancel": [KEY_ESCAPE]
	}
	for action: String in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		InputMap.action_erase_events(action)
		for key: int in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)
