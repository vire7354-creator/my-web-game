extends Control

const SOUND_FX_SCRIPT := preload("res://scripts/sound_fx.gd")

var _card: PanelContainer
var _content: VBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(_fit_card)
	resized.connect(queue_redraw)
	_build_ui()
	var sound_fx: Node = SOUND_FX_SCRIPT.new()
	add_child(sound_fx)
	var data: Dictionary = get_tree().get_meta("last_result", {})
	sound_fx.play("win" if bool(data.get("won", false)) else "fail")
	call_deferred("_fit_card")


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#dcebe4"))
	draw_rect(Rect2(0.0, size.y - 90.0, size.x, 90.0), Color("#a4c4ad"))
	for i in range(7):
		var x := 38.0 + float(i) * (size.x / 7.0)
		draw_rect(Rect2(x, 52.0, 92.0, 72.0), Color("#b7d4d0"))


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(center)
	_card = PanelContainer.new()
	_card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#fffaf0")
	panel_style.set_corner_radius_all(22)
	panel_style.set_content_margin_all(24.0)
	panel_style.shadow_color = Color(0.18, 0.27, 0.31, 0.16)
	panel_style.shadow_size = 16
	panel_style.shadow_offset = Vector2(0.0, 7.0)
	_card.add_theme_stylebox_override("panel", panel_style)
	center.add_child(_card)
	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 14)
	_card.add_child(_content)

	var data: Dictionary = get_tree().get_meta("last_result", {})
	var won := bool(data.get("won", false))
	var heading := Label.new()
	heading.text = "找到教室！" if won else String(data.get("reason", "鐘聲響了……"))
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 43)
	heading.add_theme_color_override("font_color", Color("#30485a"))
	_content.add_child(heading)
	var message := Label.new()
	message.text = "你成功趕上第一堂課。" if won else "別擔心，記住路線再試一次！"
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.add_theme_color_override("font_color", Color("#4b6266"))
	_content.add_child(message)
	var details := Label.new()
	var time_value := int(data.get("time_left", 0))
	details.text = "成績　%d 分\n抵達樓層　%d／3\n收集貼紙　%d 張　・　剩餘時間　%d:%02d" % [int(data.get("score", 0)), int(data.get("floor", 1)), int(data.get("collected", 0)), time_value / 60, time_value % 60]
	details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_theme_color_override("font_color", Color("#40585d"))
	_content.add_child(details)
	var replay := Button.new()
	replay.text = "再玩一次"
	replay.custom_minimum_size.y = 50.0
	replay.add_theme_stylebox_override("normal", _button_style(Color("#ef9a65")))
	replay.add_theme_stylebox_override("hover", _button_style(Color("#f2ae79")))
	replay.add_theme_color_override("font_color", Color.WHITE)
	replay.pressed.connect(_replay)
	_content.add_child(replay)
	var home := Button.new()
	home.text = "回到首頁"
	home.custom_minimum_size.y = 46.0
	home.add_theme_stylebox_override("normal", _button_style(Color("#d8e7df")))
	home.add_theme_stylebox_override("hover", _button_style(Color("#c3dbd0")))
	home.add_theme_color_override("font_color", Color("#30485a"))
	home.pressed.connect(func(): get_tree().change_scene_to_file("res://Main.tscn"))
	_content.add_child(home)


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ENTER:
		_replay()


func _replay() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _fit_card() -> void:
	if _card == null or _content == null:
		return
	_card.custom_minimum_size.x = clampf(size.x - 44.0, 280.0, 560.0)
	_content.custom_minimum_size.x = maxf(240.0, _card.custom_minimum_size.x - 44.0)


func _button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(14)
	style.set_content_margin_all(10.0)
	return style
