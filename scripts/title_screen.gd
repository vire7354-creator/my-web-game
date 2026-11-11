extends Control

const GAME_SCENE := preload("res://scenes/game.tscn")

var _card: PanelContainer
var _content: VBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(queue_redraw)
	resized.connect(_fit_card)
	_build_ui()
	call_deferred("_fit_card")


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#dcebe4"))
	var window_width := size.x / 8.0
	for i in range(8):
		var x := float(i) * window_width + 20.0
		draw_rect(Rect2(x, 68.0, maxf(20.0, window_width - 42.0), 100.0), Color("#b7d4d0"))
		draw_line(Vector2(x, 118.0), Vector2(x + window_width - 42.0, 118.0), Color("#f5f1df"), 4.0)
	draw_rect(Rect2(0.0, size.y - 86.0, size.x, 86.0), Color("#a4c4ad"))
	draw_rect(Rect2(0.0, size.y - 40.0, size.x, 40.0), Color("#8eb29a"))


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
	_card.add_theme_stylebox_override("panel", _panel_style(Color("#fffaf0")))
	center.add_child(_card)

	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 12)
	_card.add_child(_content)

	var eyebrow := Label.new()
	eyebrow.text = "大學生活・平台跳躍"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.add_theme_color_override("font_color", Color("#547b72"))
	_content.add_child(eyebrow)

	var title := Label.new()
	title.text = "鐘響前\n教室在哪？"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 46)
	title.add_theme_color_override("font_color", Color("#30485a"))
	_content.add_child(title)

	var story := Label.new()
	story.text = "新學期第一天，帶阿勤穿過陌生大樓。\n在鐘響前找到 3 樓的 305 教室！"
	story.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story.add_theme_color_override("font_color", Color("#4b6266"))
	_content.add_child(story)

	var instructions := Label.new()
	instructions.text = "A／D 或 ←／→ 移動，Space／W／↑ 跳躍\n手機使用畫面按鈕，可邊移動邊跳。\n收集課表貼紙，避開推車和濕滑地板。"
	instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instructions.add_theme_color_override("font_color", Color("#4b6266"))
	_content.add_child(instructions)

	var start_button := Button.new()
	start_button.text = "開始找教室"
	start_button.custom_minimum_size.y = 54.0
	start_button.add_theme_font_size_override("font_size", 23)
	start_button.add_theme_stylebox_override("normal", _button_style(Color("#ef9a65")))
	start_button.add_theme_stylebox_override("hover", _button_style(Color("#f2ae79")))
	start_button.add_theme_stylebox_override("pressed", _button_style(Color("#dc8052")))
	start_button.add_theme_color_override("font_color", Color("#39291e"))
	start_button.pressed.connect(_start_game)
	_content.add_child(start_button)

	var author := Label.new()
	author.text = "資通四勤 121271035 【謝力翔】"
	author.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	author.add_theme_color_override("font_color", Color("#547b72"))
	_content.add_child(author)

	var credits := Label.new()
	credits.text = "字型：Noto Sans TC（OFL）・Google Fonts"
	credits.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	credits.add_theme_font_size_override("font_size", 14)
	credits.add_theme_color_override("font_color", Color("#71827e"))
	_content.add_child(credits)


func _fit_card() -> void:
	if _card == null or _content == null:
		return
	_card.custom_minimum_size.x = clampf(size.x - 44.0, 280.0, 590.0)
	_content.custom_minimum_size.x = maxf(240.0, _card.custom_minimum_size.x - 44.0)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ENTER:
		get_viewport().set_input_as_handled()
		_start_game()


func _start_game() -> void:
	get_tree().change_scene_to_packed(GAME_SCENE)


func _panel_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(22)
	style.set_content_margin_all(24.0)
	style.shadow_color = Color(0.18, 0.27, 0.31, 0.16)
	style.shadow_size = 16
	style.shadow_offset = Vector2(0.0, 7.0)
	return style


func _button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(14)
	style.set_content_margin_all(10.0)
	return style
