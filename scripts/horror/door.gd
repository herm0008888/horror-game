extends Node3D
@export var open_angle: float = 95.0
var opened := false
var motion: Tween
func interact() -> void:
	set_open(not opened)
	get_tree().call_group("horror_listener", "hear_noise", global_position, 12.0)
func set_open(value: bool) -> void:
	if value == opened: return
	opened = value
	get_tree().call_group("dynamic_navigation","request_update")
	if motion: motion.kill()
	motion = create_tween()
	motion.tween_property($Hinge, "rotation:y", deg_to_rad(open_angle) if opened else 0.0, 1.1).set_trans(Tween.TRANS_SINE)
	$Creak.pitch_scale = randf_range(0.78, 1.03)
	$Creak.play()

func can_pass() -> bool:
	return opened and absf($Hinge.rotation.y) >= deg_to_rad(85.0)
