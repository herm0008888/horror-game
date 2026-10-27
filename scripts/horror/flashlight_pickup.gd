extends StaticBody3D
var taken := false
func interact() -> void:
	if taken: return
	var player := get_tree().get_first_node_in_group("horror_player")
	if not player or not player.has_method("acquire_flashlight"): return
	if player.global_position.distance_to(global_position) > 2.6: return
	taken = true
	player.acquire_flashlight()
	queue_free()
