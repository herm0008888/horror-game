extends Control
@export var car: RigidBody3D
var current_speed: float = 0.0

func _process(delta: float) -> void:
	if car:
		current_speed = lerpf(current_speed, car.linear_velocity.length() * 3.6, 1.0 - exp(-delta * 12.0))
	queue_redraw()

func _draw() -> void:
	var center := Vector2(size.x - 132.0, size.y - 124.0)
	draw_circle(center, 91.0, Color(0.015, 0.025, 0.035, 0.72))
	draw_arc(center, 88.0, 0, TAU, 96, Color(0.7,0.83,0.88,0.15), 1.0, true)
	var start := PI * 0.75
	var sweep := PI * 1.5
	draw_arc(center, 78.0, start, start + sweep, 80, Color(0.7,0.83,0.88,0.20), 3.0, true)
	draw_arc(center, 78.0, start, start + sweep * clampf(current_speed / 220.0, 0.001, 1.0), 80, Color(0.36,0.88,0.94), 3.0, true)
	var font := ThemeDB.fallback_font
	for i in range(12):
		var a := start + sweep * i / 11.0
		var direction := Vector2(cos(a), sin(a))
		draw_line(center + direction * 69.0, center + direction * 74.0, Color(0.8,0.87,0.9,0.65), 1.0, true)
	var number := str(roundi(current_speed))
	var text_size := font.get_string_size(number, HORIZONTAL_ALIGNMENT_LEFT, -1, 44)
	draw_string(font, center + Vector2(-text_size.x / 2.0, 12), number, HORIZONTAL_ALIGNMENT_LEFT, -1, 44, Color(0.94,0.98,1))
	draw_string(font, center + Vector2(-18, 36), "km/h", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.65,0.76,0.8))
