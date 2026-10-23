extends BroadsideShip

func _physics_process(delta: float) -> void:
	step(delta, Input.get_axis("brake", "throttle"), Input.get_axis("port", "starboard"))

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("fire") and not event.is_echo():
		fire_loaded()
		get_viewport().set_input_as_handled()
