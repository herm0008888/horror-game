extends SceneTree
var errors: Array[String] = []
func _initialize() -> void: call_deferred("run")
func run() -> void:
	set_meta("creature_situation",4)
	var scene := load("res://scenes/horror/test_area.tscn").instantiate() as Node3D
	root.add_child(scene)
	current_scene = scene
	for i in range(5): await physics_frame
	var player: CharacterBody3D = scene.get_node("Player")
	var enemy: CharacterBody3D = scene.get_node("Visitation")
	player.set_physics_process(false)
	enemy.set_physics_process(false)
	var skeleton: Skeleton3D = enemy.pose_skeleton
	if enemy.eye_gaze.eyes.size() != 2: errors.append("Two independent eye bones required")
	if not enemy.pose_bones.has("Tongue"): errors.append("Missing skinned tongue")
	for offset in [Vector3(1.8,1.65,3),Vector3(-1.8,1.65,3),Vector3(0,0.95,2.5)]:
		player.camera.global_position = enemy.global_position+offset
		for i in range(24):
			enemy.track_player_head(1.0/60.0)
			enemy.eye_gaze.track(player.camera.global_position,1.0/60.0)
		for index in enemy.eye_gaze.eyes:
			var pose := skeleton.get_bone_global_pose(index)
			var rest := skeleton.get_bone_global_rest(index).basis.orthonormalized()
			var forward := (skeleton.global_basis.orthonormalized()*pose.basis.orthonormalized()*rest.inverse()*Vector3.FORWARD).normalized()
			var direction: Vector3 = (player.camera.global_position-skeleton.global_transform*pose.origin).normalized()
			var alignment := forward.dot(direction)
			print("EYE_ALIGNMENT ",alignment)
			if alignment < 0.995: errors.append("Pupil does not face camera")
	print("VISCERAL_EYES_TEST ","PASS" if errors.is_empty() else errors)
	quit(0 if errors.is_empty() else 1)

