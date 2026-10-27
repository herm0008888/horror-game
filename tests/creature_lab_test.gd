extends SceneTree
var errors: Array[String] = []
func _initialize() -> void: call_deferred("run")
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func check(ok: bool, label: String) -> void:
	if not ok: errors.append(label)
func run() -> void:
	var scene := load("res://scenes/horror/test_area.tscn").instantiate() as Node3D
	root.add_child(scene)
	current_scene = scene
	var player: CharacterBody3D = scene.get_node("Player")
	var enemy: CharacterBody3D = scene.get_node("Visitation")
	enemy.set_physics_process(false)
	await frames(30)
	check(not player.has_flashlight and not player.torch.visible, "Starts without flashlight")
	var toggle := InputEventAction.new()
	toggle.action = "flashlight"
	toggle.pressed = true
	player._unhandled_input(toggle)
	check(not player.torch.visible, "Cannot use flashlight before pickup")
	player.set_physics_process(false)
	player.camera.look_at(scene.get_node("FlashlightPickup").global_position)
	var interact := InputEventAction.new()
	interact.action = "interact"
	interact.pressed = true
	player._unhandled_input(interact)
	await frames(2)
	check(player.has_flashlight and player.torch.visible and player.held_torch.visible, "Raycast E pickup equips flashlight")
	check(not is_instance_valid(scene.get_node_or_null("FlashlightPickup")), "World pickup removed")
	check(not InputMap.has_action("sprint"), "No sprint input")
	player.camera.rotation = Vector3.ZERO
	player.set_physics_process(true)
	var start := player.position
	Input.action_press("move_forward")
	await frames(60)
	Input.action_release("move_forward")
	check(player.position.distance_to(start) < 1.9 and player.position.distance_to(start) > 1.1, "Slower walking and acceleration")
	check(not player.sprinting, "Sprinting disabled")
	player.set_physics_process(false)
	player.position = Vector3(0,0.05,5)
	enemy.position = Vector3(0,0.05,-2)
	enemy.figure.rotation.y = PI
	enemy.set_physics_process(true)
	await frames(12)
	check(enemy.has_seen_player, "Sight locks head tracking")
	enemy.set_physics_process(false)
	player.position.x = 2
	enemy.track_player_head(1.0/60.0)
	var skeleton: Skeleton3D = enemy.pose_skeleton
	var index: int = enemy.pose_bones["Head"]
	var pose := skeleton.get_bone_global_pose(index)
	var neutral := skeleton.get_bone_global_rest(index).basis.orthonormalized()
	var front := (skeleton.global_basis.orthonormalized() * pose.basis.orthonormalized() * neutral.inverse() * Vector3.FORWARD).normalized()
	var head_world := skeleton.global_transform * (pose * (skeleton.get_bone_global_rest(index).affine_inverse() * Vector3(0,1.905,-0.26)))
	var target: Vector3 = (player.camera.global_position-head_world).normalized()
	var alignment := front.dot(target)
	print("HEAD_ALIGNMENT ", alignment)
	check(alignment > 0.98, "Head faces player camera independently of body")
	check(enemy.get_node("Collision").shape.height > player.get_node("Collision").shape.height + 0.6, "Enemy taller than player")
	enemy.motion.elapsed = 2.7
	var stalled: float = enemy.motion.speed_factor(true)
	enemy.motion.elapsed = 1.0
	check(stalled < enemy.motion.speed_factor(true), "Intentional stuttering locomotion")
	player.position = Vector3(0,0.05,4.0)
	player.camera.look_at(Vector3(0,1.45,-2))
	enemy.motion.animate(1.0/60.0,true,true,enemy.figure,skeleton,enemy.pose_bones,enemy.pose_rest_rotations)
	enemy.track_player_head(1.0/60.0)
	if DisplayServer.get_name() != "headless":
		for i in range(4): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../creature-test-area.png")
	print("CREATURE_LAB_TEST ", "PASS" if errors.is_empty() else errors)
	quit(0 if errors.is_empty() else 1)

