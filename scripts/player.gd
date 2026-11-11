extends CharacterBody2D

signal damaged
signal jumped

const RUN_SPEED := 290.0
const JUMP_SPEED := -570.0
const GRAVITY := 1500.0

var invulnerability_left := 0.0
var _facing := 1.0
var _jump_buffer := 0.0
var _coyote_time := 0.0
var _knockback := 0.0
var touch_left := false
var touch_right := false


func _physics_process(delta: float) -> void:
	var direction := 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction += 1.0
	if touch_left:
		direction -= 1.0
	if touch_right:
		direction += 1.0
	direction = clampf(direction, -1.0, 1.0)
	if direction != 0.0:
		_facing = signf(direction)
	_knockback = move_toward(_knockback, 0.0, 1300.0 * delta)
	velocity.x = direction * RUN_SPEED + _knockback
	if position.x <= 18.0 and velocity.x < 0.0:
		velocity.x = 0.0
	velocity.y = minf(velocity.y + GRAVITY * delta, 1000.0)

	if is_on_floor():
		_coyote_time = 0.09
	else:
		_coyote_time = maxf(0.0, _coyote_time - delta)
	if _jump_buffer > 0.0 and _coyote_time > 0.0:
		velocity.y = JUMP_SPEED
		_coyote_time = 0.0
		_jump_buffer = 0.0
		jumped.emit()
	_jump_buffer = maxf(0.0, _jump_buffer - delta)

	if invulnerability_left > 0.0:
		invulnerability_left = maxf(0.0, invulnerability_left - delta)
	move_and_slide()
	queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode in [KEY_SPACE, KEY_W, KEY_UP]:
			request_touch_jump()


func take_damage(source_position: Vector2, force: bool = false) -> bool:
	if invulnerability_left > 0.0 and not force:
		return false
	invulnerability_left = 1.15
	var knockback_direction := signf(global_position.x - source_position.x)
	if knockback_direction == 0.0:
		knockback_direction = -1.0
	_knockback = knockback_direction * 260.0
	velocity.y = -300.0
	damaged.emit()
	return true


func respawn(at_position: Vector2) -> void:
	global_position = at_position
	velocity = Vector2.ZERO
	_knockback = 0.0
	_coyote_time = 0.0
	_jump_buffer = 0.0
	invulnerability_left = 1.0


func set_touch_left(pressed: bool) -> void:
	touch_left = pressed


func set_touch_right(pressed: bool) -> void:
	touch_right = pressed


func request_touch_jump() -> void:
	_jump_buffer = 0.13


func _draw() -> void:
	var stride := sin(float(Time.get_ticks_msec()) * 0.022) * 5.0 if is_on_floor() and absf(velocity.x) > 10.0 else 0.0
	var stretch := 1.0 + clampf(-velocity.y / 1900.0, -0.08, 0.14) if not is_on_floor() else 1.0
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(_facing / stretch, stretch))
	var blink := invulnerability_left > 0.0 and int(invulnerability_left * 14.0) % 2 == 0
	var jacket := Color("#e9804f") if not blink else Color("#fff5df")
	var skin := Color("#f2c6a0")
	var dark := Color("#34455b")
	# Backpack and straps.
	draw_rect(Rect2(Vector2(-17.0, -11.0), Vector2(10.0, 25.0)), Color("#3e7180"), true)
	draw_rect(Rect2(Vector2(-8.0, -15.0), Vector2(19.0, 27.0)), jacket, true)
	# Head and hair.
	draw_circle(Vector2(1.0, -24.0), 12.0, skin)
	draw_arc(Vector2(1.0, -26.0), 12.0, PI, TAU, 16, dark, 6.0, true)
	draw_circle(Vector2(5.0 + _facing * 3.0, -24.0), 1.4, dark)
	# Legs and shoes.
	draw_line(Vector2(-3.0, 11.0), Vector2(-6.0 + stride, 22.0), dark, 5.0, true)
	draw_line(Vector2(7.0, 11.0), Vector2(9.0 - stride, 22.0), dark, 5.0, true)
	draw_line(Vector2(-8.0 + stride, 22.0), Vector2(-1.0 + stride, 22.0), dark, 4.0, true)
	draw_line(Vector2(7.0 - stride, 22.0), Vector2(14.0 - stride, 22.0), dark, 4.0, true)
	# A small timetable peeking from the backpack strap.
	draw_rect(Rect2(Vector2(10.0, -10.0), Vector2(8.0, 12.0)), Color("#f5d56d"), true)
	draw_line(Vector2(12.0, -6.0), Vector2(16.0, -6.0), Color("#9a7542"), 1.0)
