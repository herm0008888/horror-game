extends Node3D
@export var label: String = "Dør"
@export var floor_hatch: bool = false
@export var open_angle: float = 100.0
var opened := false
var motion: Tween

func interact() -> void: set_open(not opened)

func set_open(value: bool) -> void:
	if opened == value: return
	opened = value
	get_tree().call_group("dynamic_navigation","request_update")
	if motion: motion.kill()
	motion = create_tween()
	var property := "rotation:x" if floor_hatch else "rotation:y"
	motion.tween_property($Hinge, property, deg_to_rad(open_angle) if opened else 0.0, 0.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	$Creak.pitch_scale = randf_range(0.8, 1.05)
	$Creak.play()
	get_tree().call_group("horror_listener", "hear_noise", global_position, 10.0)

func can_pass() -> bool: return opened and not motion.is_running()

func prompt() -> String:
	return "E  ·  %s %s" % ["Lukk" if opened else "Åpne", label.to_lower()]
