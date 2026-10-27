extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var scene := load("res://scenes/horror/main.tscn").instantiate() as Node3D
	root.add_child(scene)
	current_scene = scene
	var player: CharacterBody3D = scene.get_node("Player")
	var enemy: CharacterBody3D = scene.get_node("Visitation")
	player.set_physics_process(false)
	enemy.set_physics_process(false)
	player.position = Vector3(0, 0.05, 6)
	player.camera.look_at(Vector3(0, 1.2, 2.8))
	enemy.position = Vector3(0, 0.05, 2.8)
	enemy.figure.rotation.y = PI
	var first_head := Quaternion.IDENTITY
	for frame in range(180):
		enemy.motion.animate(1.0 / 60.0, true, true, enemy.figure, enemy.pose_skeleton, enemy.pose_bones, enemy.pose_rest_rotations)
		await process_frame
		if frame == 35: first_head = enemy.pose_skeleton.get_bone_pose_rotation(enemy.pose_bones["Head"])
		if frame in [35, 95, 155] and DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://../haunted-game-%s.png" % frame)
	var final_head: Quaternion = enemy.pose_skeleton.get_bone_pose_rotation(enemy.pose_bones["Head"])
	var changed: bool = first_head.angle_to(final_head) > 0.02
	print("HAUNTED_ANIMATION ", "PASS" if changed else "FAIL", " head_motion=", first_head.angle_to(final_head))
	quit(0 if changed else 1)
