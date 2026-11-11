extends Area2D

@export var kind := "cart"
@export var moving := true
@export var patrol_distance := 70.0
@export var patrol_speed := 1.7

var _home_x := 0.0
var _phase := 0.0
var speed_multiplier := 1.0


func _ready() -> void:
	_home_x = position.x
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if moving:
		_phase += delta * patrol_speed * speed_multiplier
		position.x = _home_x + sin(_phase) * patrol_distance


func _draw() -> void:
	if kind == "spill":
		draw_colored_polygon(PackedVector2Array([
			Vector2(-31.0, 0.0), Vector2(-22.0, -8.0), Vector2(-7.0, -11.0),
			Vector2(14.0, -9.0), Vector2(31.0, -2.0), Vector2(24.0, 7.0),
			Vector2(3.0, 11.0), Vector2(-18.0, 8.0)
		]), Color("#67a9b1"))
		draw_arc(Vector2.ZERO, 22.0, PI, TAU, 16, Color("#b8e5df"), 2.0, true)
	elif kind == "student":
		draw_circle(Vector2(0.0, -16.0), 9.0, Color("#eac4a1"))
		draw_rect(Rect2(Vector2(-11.0, -8.0), Vector2(22.0, 25.0)), Color("#9278a8"), true)
		draw_line(Vector2(-6.0, 16.0), Vector2(-9.0, 26.0), Color("#394b60"), 4.0, true)
		draw_line(Vector2(6.0, 16.0), Vector2(9.0, 26.0), Color("#394b60"), 4.0, true)
	else:
		draw_rect(Rect2(Vector2(-22.0, -11.0), Vector2(44.0, 24.0)), Color("#e1a54c"), true)
		draw_rect(Rect2(Vector2(-13.0, -18.0), Vector2(20.0, 9.0)), Color("#f3d47a"), true)
		draw_circle(Vector2(-13.0, 15.0), 5.0, Color("#3d5261"))
		draw_circle(Vector2(14.0, 15.0), 5.0, Color("#3d5261"))


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(global_position)
