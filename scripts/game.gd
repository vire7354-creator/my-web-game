extends Node2D

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const HAZARD_SCENE := preload("res://scenes/hazard.tscn")
const COLLECTIBLE_SCENE := preload("res://scenes/collectible.tscn")
const RESULT_SCENE := preload("res://scenes/result_screen.tscn")
const SOUND_FX_SCRIPT := preload("res://scripts/sound_fx.gd")
const TOUCH_CONTROLS_SCRIPT := preload("res://scripts/touch_controls.gd")

const LEVEL_WIDTH := 4100.0
const START_TIME := 120.0

var score := 0
var lives := 3
var time_left := START_TIME
var collected_count := 0
var current_floor := 1
var checkpoint_floor := 1
var checkpoint_position := Vector2(70.0, 583.0)
var player: CharacterBody2D
var hud_score: Label
var hud_time: Label
var hud_lives: Label
var hud_floor: Label
var hazards: Array[Area2D] = []
var sound_fx: Node
var _camera: Camera2D
var _flash: ColorRect
var _moving_platform: AnimatableBody2D
var _moving_phase := 0.0
var _spawned_hazard_floor := 1
var finished := false


func _ready() -> void:
	_build_level()
	_build_player()
	sound_fx = SOUND_FX_SCRIPT.new()
	add_child(sound_fx)
	_build_hud()
	_update_hud()


func _process(delta: float) -> void:
	if finished:
		return
	time_left = maxf(0.0, time_left - delta)
	if player != null:
		_update_progress()
		_update_difficulty()
		if player.global_position.y > 850.0:
			player.take_damage(player.global_position + Vector2(0.0, 100.0), true)
			player.respawn(checkpoint_position)
	if time_left <= 0.0:
		_finish(false)
	_update_hud()


func _physics_process(delta: float) -> void:
	if _moving_platform != null and not finished:
		_moving_phase += delta * (1.65 if time_left > 40.0 else 2.15)
		_moving_platform.position.x = 3198.0 + sin(_moving_phase) * 42.0


func _draw() -> void:
	draw_rect(Rect2(0.0, 0.0, LEVEL_WIDTH, 2400.0), Color("#e6eee9"))
	draw_rect(Rect2(0.0, 0.0, LEVEL_WIDTH, 154.0), Color("#d6e8e2"))
	for i in range(16):
		var x := 45.0 + float(i) * 265.0
		draw_rect(Rect2(x, 38.0, 118.0, 82.0), Color("#a6cbc6"))
		draw_rect(Rect2(x + 53.0, 38.0, 6.0, 82.0), Color("#edf2df"))
		draw_rect(Rect2(x, 76.0, 118.0, 5.0), Color("#edf2df"))
	# Floor bands and corridor signs.
	draw_rect(Rect2(0.0, 600.0, LEVEL_WIDTH, 17.0), Color("#b1c8bc"))
	draw_rect(Rect2(1320.0, 430.0, LEVEL_WIDTH - 1320.0, 16.0), Color("#b9cfc3"))
	draw_rect(Rect2(2510.0, 280.0, LEVEL_WIDTH - 2510.0, 16.0), Color("#c4d7c9"))
	draw_rect(Rect2(45.0, 460.0, 180.0, 44.0), Color("#f3d786"))
	draw_rect(Rect2(1370.0, 334.0, 190.0, 44.0), Color("#f3d786"))
	draw_rect(Rect2(2570.0, 188.0, 170.0, 44.0), Color("#f3d786"))


func _build_level() -> void:
	var platform_data: Array[Dictionary] = [
		{"x": 0.0, "y": 620.0, "width": 500.0, "floor": 1},
		{"x": 430.0, "y": 565.0, "width": 175.0, "floor": 1},
		{"x": 650.0, "y": 520.0, "width": 180.0, "floor": 1},
		{"x": 875.0, "y": 565.0, "width": 185.0, "floor": 1},
		{"x": 1090.0, "y": 500.0, "width": 185.0, "floor": 1},
		{"x": 1310.0, "y": 450.0, "width": 235.0, "floor": 2},
		{"x": 1515.0, "y": 420.0, "width": 175.0, "floor": 2},
		{"x": 1715.0, "y": 370.0, "width": 180.0, "floor": 2},
		{"x": 1925.0, "y": 410.0, "width": 175.0, "floor": 2},
		{"x": 2130.0, "y": 350.0, "width": 180.0, "floor": 2},
		{"x": 2335.0, "y": 315.0, "width": 190.0, "floor": 2},
		{"x": 2510.0, "y": 300.0, "width": 225.0, "floor": 3},
		{"x": 2725.0, "y": 270.0, "width": 175.0, "floor": 3},
		{"x": 2925.0, "y": 225.0, "width": 180.0, "floor": 3},
		{"x": 3340.0, "y": 230.0, "width": 190.0, "floor": 3},
		{"x": 3555.0, "y": 190.0, "width": 330.0, "floor": 3},
	]
	for data in platform_data:
		_add_platform(float(data["x"]), float(data["y"]), float(data["width"]), int(data["floor"]))
	_moving_platform = _add_platform(3148.0, 259.0, 100.0, 3, true) as AnimatableBody2D
	_add_sign(Vector2(57.0, 465.0), "1F　教學大樓")
	_add_sign(Vector2(1383.0, 339.0), "2F　走廊施工中")
	_add_sign(Vector2(2583.0, 193.0), "3F　教室區")
	_add_hazard(Vector2(936.0, 553.0), "spill", false, 0.0, 0.0)
	for item_position in [Vector2(400.0, 526.0), Vector2(700.0, 482.0), Vector2(1150.0, 462.0), Vector2(1585.0, 381.0), Vector2(1795.0, 331.0), Vector2(2200.0, 311.0), Vector2(2700.0, 231.0), Vector2(3065.0, 184.0), Vector2(3400.0, 168.0)]:
		_add_collectible(item_position)
	_add_goal()


func _build_player() -> void:
	player = PLAYER_SCENE.instantiate()
	player.position = checkpoint_position
	player.damaged.connect(_on_player_damaged)
	player.jumped.connect(_on_player_jumped)
	add_child(player)
	_camera = Camera2D.new()
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = 5.0
	_camera.limit_left = 0
	_camera.limit_right = int(LEVEL_WIDTH)
	_camera.limit_top = 0
	_camera.limit_bottom = 2400
	player.add_child(_camera)
	_camera.make_current()


func _add_platform(x: float, y: float, width: float, floor_number: int, moving: bool = false) -> PhysicsBody2D:
	var platform: PhysicsBody2D = AnimatableBody2D.new() if moving else StaticBody2D.new()
	platform.position = Vector2(x + width / 2.0, y)
	platform.collision_layer = 1
	platform.collision_mask = 1
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(width, 22.0)
	collision.shape = rectangle
	collision.one_way_collision = true
	platform.add_child(collision)
	var visual := Polygon2D.new()
	visual.polygon = PackedVector2Array([Vector2(-width / 2.0, -11.0), Vector2(width / 2.0, -11.0), Vector2(width / 2.0, 11.0), Vector2(-width / 2.0, 11.0)])
	var palette := [Color("#77a58f"), Color("#789c9b"), Color("#8c9e7e")]
	visual.color = palette[clampi(floor_number - 1, 0, 2)]
	if moving:
		visual.color = Color("#c18157")
	platform.add_child(visual)
	var edge := Line2D.new()
	edge.points = PackedVector2Array([Vector2(-width / 2.0, -9.0), Vector2(width / 2.0, -9.0)])
	edge.width = 4.0
	edge.default_color = Color("#e7d69a")
	platform.add_child(edge)
	add_child(platform)
	return platform


func _add_sign(at: Vector2, text_value: String) -> void:
	var label := Label.new()
	label.text = text_value
	label.position = at
	label.add_theme_color_override("font_color", Color("#4b5d5c"))
	label.add_theme_font_size_override("font_size", 21)
	add_child(label)


func _add_hazard(at: Vector2, kind: String, moving: bool, distance: float, speed: float) -> void:
	var hazard: Area2D = HAZARD_SCENE.instantiate()
	hazard.position = at
	hazard.kind = kind
	hazard.moving = moving
	hazard.patrol_distance = distance
	hazard.patrol_speed = speed
	hazards.append(hazard)
	add_child(hazard)


func _add_collectible(at: Vector2) -> void:
	var item: Area2D = COLLECTIBLE_SCENE.instantiate()
	item.position = at
	item.collected.connect(_on_collectible_collected)
	add_child(item)


func _add_goal() -> void:
	var goal := Area2D.new()
	goal.position = Vector2(3780.0, 112.0)
	goal.collision_layer = 2
	goal.collision_mask = 1
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(72.0, 142.0)
	collision.shape = rectangle
	goal.add_child(collision)
	var door := Polygon2D.new()
	door.polygon = PackedVector2Array([Vector2(-30.0, -60.0), Vector2(30.0, -60.0), Vector2(30.0, 62.0), Vector2(-30.0, 62.0)])
	door.color = Color("#b87558")
	goal.add_child(door)
	var sign := Polygon2D.new()
	sign.polygon = PackedVector2Array([Vector2(-36.0, -85.0), Vector2(36.0, -85.0), Vector2(36.0, -63.0), Vector2(-36.0, -63.0)])
	sign.color = Color("#f3d786")
	goal.add_child(sign)
	var number := Label.new()
	number.text = "305"
	number.position = Vector2(-19.0, -87.0)
	number.add_theme_font_size_override("font_size", 16)
	number.add_theme_color_override("font_color", Color("#30485a"))
	goal.add_child(number)
	goal.body_entered.connect(_on_goal_body_entered)
	add_child(goal)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 2
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)
	var bar := PanelContainer.new()
	bar.anchor_left = 0.0
	bar.anchor_right = 1.0
	bar.offset_left = 24.0
	bar.offset_right = -24.0
	bar.offset_top = 18.0
	bar.offset_bottom = 82.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.99, 0.98, 0.92, 0.94)
	style.set_corner_radius_all(17)
	style.set_content_margin_all(12.0)
	bar.add_theme_stylebox_override("panel", style)
	root.add_child(bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	bar.add_child(row)
	hud_score = _make_hud_label()
	hud_time = _make_hud_label()
	hud_lives = _make_hud_label()
	hud_floor = _make_hud_label()
	for label in [hud_score, hud_time, hud_lives, hud_floor]:
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
	var hint := Label.new()
	hint.text = "A／D 或 ←／→ 移動　・　Space／W／↑ 跳躍"
	hint.anchor_left = 0.0
	hint.anchor_right = 1.0
	hint.anchor_top = 1.0
	hint.anchor_bottom = 1.0
	hint.offset_left = 24.0
	hint.offset_right = -24.0
	hint.offset_top = -39.0
	hint.offset_bottom = -12.0
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 17)
	hint.add_theme_color_override("font_color", Color("#415959"))
	root.add_child(hint)
	_build_touch_controls(root)
	_flash = ColorRect.new()
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash.color = Color(1.0, 0.35, 0.28, 0.0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_flash)


func _build_touch_controls(root: Control) -> void:
	var controls := TOUCH_CONTROLS_SCRIPT.new()
	controls.player = player
	controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	controls.visible = DisplayServer.is_touchscreen_available() or OS.has_feature("web")
	root.add_child(controls)
	controls.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for index in range(3):
		var button := _make_touch_button(["◀", "▶", "跳"][index])
		controls.add_child(button)
		button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT if index == 2 else Control.PRESET_BOTTOM_LEFT)
		button.position += Vector2(-108.0 if index == 2 else 22.0 + 98.0 * index, -126.0)
		button.size = Vector2(86.0, 78.0)
		controls.buttons.append(button)


func _make_touch_button(text_value: String) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(70.0, 70.0)
	button.add_theme_font_size_override("font_size", 26)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.99, 0.98, 0.92, 0.78)
	normal.set_corner_radius_all(35)
	normal.set_content_margin_all(8.0)
	button.add_theme_stylebox_override("normal", normal)
	var pressed := StyleBoxFlat.new()
	pressed.bg_color = Color(0.93, 0.63, 0.39, 0.92)
	pressed.set_corner_radius_all(35)
	pressed.set_content_margin_all(8.0)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("hover", normal)
	button.add_theme_color_override("font_color", Color("#30485a"))
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.toggle_mode = true
	return button


func _make_hud_label() -> Label:
	var label := Label.new()
	label.add_theme_color_override("font_color", Color("#30485a"))
	label.add_theme_font_size_override("font_size", 20)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label


func _update_progress() -> void:
	var x := player.global_position.x
	if x >= 2510.0:
		current_floor = 3
		if checkpoint_floor < 3 and player.is_on_floor():
			checkpoint_floor = 3
			checkpoint_position = Vector2(2625.0, 265.0)
			_award_checkpoint()
	elif x >= 1310.0:
		current_floor = 2
		if checkpoint_floor < 2 and player.is_on_floor():
			checkpoint_floor = 2
			checkpoint_position = Vector2(1410.0, 415.0)
			_award_checkpoint()
	else:
		current_floor = 1


func _award_checkpoint() -> void:
	score += 150
	sound_fx.play("collect")
	_show_score_popup(player.global_position, 150)


func _update_difficulty() -> void:
	if current_floor >= 2 and _spawned_hazard_floor < 2:
		_spawned_hazard_floor = 2
		_add_hazard(Vector2(1810.0, 344.0), "student", true, 57.0, 1.8)
		_add_hazard(Vector2(2255.0, 324.0), "cart", true, 38.0, 2.0)
	if current_floor >= 3 and _spawned_hazard_floor < 3:
		_spawned_hazard_floor = 3
		_add_hazard(Vector2(2940.0, 199.0), "student", true, 14.0, 3.1)
		_add_hazard(Vector2(3692.0, 163.0), "cart", true, 16.0, 2.3)
	var elapsed := START_TIME - time_left
	var time_bonus := 0.0
	if elapsed >= 60.0:
		time_bonus += 0.18
	if time_left <= 40.0:
		time_bonus += 0.22
	var multiplier := 1.0 + float(current_floor - 1) * 0.18 + time_bonus
	for hazard in hazards:
		hazard.speed_multiplier = multiplier


func _update_hud() -> void:
	if hud_score == null:
		return
	hud_score.text = "分數　%d" % score
	var seconds := ceili(time_left)
	hud_time.text = "時間　%02d:%02d" % [seconds / 60, seconds % 60]
	hud_time.modulate = Color("#d26950") if time_left <= 40.0 else Color.WHITE
	hud_lives.text = "生命　%s" % ("♥".repeat(lives) + "♡".repeat(maxi(0, 3 - lives)))
	hud_floor.text = "樓層　%d／3" % current_floor


func _on_collectible_collected(points: int, _world_position: Vector2) -> void:
	score += points
	collected_count += 1
	sound_fx.play("collect")
	_show_score_popup(_world_position, points)
	_update_hud()


func _on_player_damaged() -> void:
	lives -= 1
	sound_fx.play("hurt")
	_flash_damage()
	_update_hud()
	if lives <= 0:
		_finish(false)


func _on_player_jumped() -> void:
	sound_fx.play("jump")


func _show_score_popup(at_position: Vector2, points: int) -> void:
	var popup := Label.new()
	popup.text = "+%d" % points
	popup.position = at_position + Vector2(-28.0, -22.0)
	popup.add_theme_font_size_override("font_size", 24)
	popup.add_theme_color_override("font_color", Color("#b78229"))
	add_child(popup)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(popup, "position", popup.position + Vector2(0.0, -52.0), 0.75)
	tween.tween_property(popup, "modulate:a", 0.0, 0.75)
	tween.chain().tween_callback(popup.queue_free)


func _flash_damage() -> void:
	if _flash == null:
		return
	var tween := create_tween()
	tween.tween_property(_flash, "color", Color(1.0, 0.35, 0.28, 0.34), 0.05)
	tween.tween_property(_flash, "color", Color(1.0, 0.35, 0.28, 0.0), 0.26)
	if _camera != null:
		_camera.offset = Vector2(randf_range(-7.0, 7.0), randf_range(-5.0, 5.0))
		create_tween().tween_property(_camera, "offset", Vector2.ZERO, 0.2)


func _on_goal_body_entered(body: Node2D) -> void:
	if body == player:
		_finish(true)


func _finish(won: bool) -> void:
	if finished:
		return
	finished = true
	if won:
		score += int(time_left) * 10 + lives * 100
	get_tree().set_meta("last_result", {
		"won": won,
		"score": score,
		"time_left": int(time_left),
		"floor": checkpoint_floor,
		"collected": collected_count,
		"reason": "愛心用完了" if lives <= 0 else "鐘聲響了……",
	})
	get_tree().call_deferred("change_scene_to_packed", RESULT_SCENE)
