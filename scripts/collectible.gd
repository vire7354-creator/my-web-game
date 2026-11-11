extends Area2D

signal collected(points: int, world_position: Vector2)

@export var points := 100

var _phase := 0.0
var _origin_y := 0.0


func _ready() -> void:
	_origin_y = position.y
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_phase += delta * 2.4
	position.y = _origin_y + sin(_phase) * 4.0


func _draw() -> void:
	var points_list := PackedVector2Array([
		Vector2(0.0, -18.0), Vector2(16.0, -10.0), Vector2(13.0, 9.0),
		Vector2(0.0, 18.0), Vector2(-13.0, 9.0), Vector2(-16.0, -10.0)
	])
	draw_colored_polygon(points_list, Color("#f3cf64"))
	draw_circle(Vector2.ZERO, 6.0, Color("#fff4bb"))
	draw_line(Vector2(-5.0, 0.0), Vector2(5.0, 0.0), Color("#b78935"), 2.0, true)


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		collected.emit(points, global_position)
		queue_free()
