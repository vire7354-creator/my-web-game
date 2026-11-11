extends Control

var buttons: Array[Button] = []
var player: CharacterBody2D
var _fingers: Dictionary = {}
var _mouse_button := -1


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		if event.pressed and not event.canceled:
			var index := _hit_button(event.position)
			if index == -1:
				return
			_fingers[event.index] = index
			if index == 2:
				player.request_touch_jump()
		elif _fingers.has(event.index):
			_fingers.erase(event.index)
		else:
			return
	elif event is InputEventScreenDrag and _fingers.has(event.index):
		if _fingers[event.index] != 2:
			var index := _hit_button(event.position)
			_fingers[event.index] = index if index in [0, 1] else -1
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.device != InputEvent.DEVICE_ID_EMULATION:
		if event.pressed:
			_mouse_button = _hit_button(event.position)
			if _mouse_button == -1:
				return
			if _mouse_button == 2:
				player.request_touch_jump()
		else:
			_mouse_button = -1
	else:
		return
	_update_buttons()
	get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(player):
		_fingers.clear()
		_mouse_button = -1
		_update_buttons()


func _hit_button(at: Vector2) -> int:
	for index in range(buttons.size()):
		if buttons[index].get_global_rect().has_point(at):
			return index
	return -1


func _update_buttons() -> void:
	var pressed := _fingers.values()
	pressed.append(_mouse_button)
	player.set_touch_left(0 in pressed)
	player.set_touch_right(1 in pressed)
	for index in range(buttons.size()):
		buttons[index].set_pressed_no_signal(index in pressed)
