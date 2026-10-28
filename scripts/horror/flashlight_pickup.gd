extends RigidBody3D
var taken := false
var light_on:=true
func set_light_state(enabled: bool) -> void:
	light_on=enabled
	$DroppedBeam.visible=enabled
func interact() -> void:
	if taken: return
	var player := get_tree().get_first_node_in_group("horror_player")
	if not player or not player.has_method("acquire_flashlight"): return
	if player.global_position.distance_to(global_position) > 2.6: return
	if player.call("acquire_flashlight",light_on)==false: return
	taken = true
	queue_free()
