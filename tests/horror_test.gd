extends SceneTree
var errors: Array[String] = []
func _initialize() -> void: call_deferred("run")
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func require(condition: bool, label: String) -> void:
	if not condition: errors.append(label)
func run() -> void:
	var scene := load("res://scenes/horror/main.tscn").instantiate() as Node3D
	root.add_child(scene)
	current_scene = scene
	var player: CharacterBody3D = scene.get_node("Player")
	var enemy: CharacterBody3D = scene.get_node("Visitation")
	enemy.set_physics_process(false)
	await frames(60)
	require(player.is_on_floor(), "Player floor collision")
	var floor_y := player.position.y
	var space := InputEventKey.new()
	space.physical_keycode = KEY_SPACE
	space.pressed = true
	Input.parse_input_event(space)
	await frames(15)
	require(absf(player.position.y - floor_y) < 0.02 and player.velocity.y <= 0, "Space cannot trigger a jump")
	space.pressed = false
	Input.parse_input_event(space)
	require(not InputMap.has_action("jump"), "No jump action bound")
	var origin := player.position
	Input.action_press("move_forward")
	await frames(60)
	Input.action_release("move_forward")
	require(player.position.distance_to(origin) > 2, "First person movement")
	var door: Node3D = scene.get_node("House/Doors/Door1")
	door.set_open(true)
	await frames(80)
	require(absf(door.get_node("Hinge").rotation.y) > 1.2, "Door hinge opens")
	# Ramp traversal with the same capsule and gravity as normal play.
	player.position = Vector3(3.25,.15,-1.4)
	player.rotation = Vector3.ZERO
	Input.action_press("move_forward")
	await frames(240)
	Input.action_release("move_forward")
	await frames(20)
	print("STAIR_POSITION ", player.position)
	require(player.position.y > 3.0, "Staircase traversal")
	require(enemy.graph.get_point_count() == 25, "Authored AI waypoint graph")
	require(enemy.pose_skeleton != null and enemy.pose_bones.has("Head") and enemy.pose_bones.has("ArmLeft"), "Skinned character skeleton")
	# Force a clear hallway encounter and verify sight-based pursuit.
	enemy.position = Vector3(0,.05,1)
	enemy.figure.rotation.y = PI
	enemy.set_physics_process(true)
	player.position = Vector3(0,.05,6)
	player.velocity = Vector3.ZERO
	await frames(45)
	require(enemy.hunt > 0, "Enemy sees player")
	var shoulder: Vector3 = enemy.pose_skeleton.global_transform * enemy.pose_skeleton.get_bone_global_pose(enemy.pose_bones["ArmLeft"]).origin
	var elbow: Vector3 = enemy.pose_skeleton.global_transform * enemy.pose_skeleton.get_bone_global_pose(enemy.pose_bones["ForearmLeft"]).origin
	require(elbow.y < shoulder.y - 0.1, "Arm animation preserves authored rest pose")
	if DisplayServer.get_name() != "headless":
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../horror-preview.png")
	print("HORROR_TEST ", "PASS" if errors.is_empty() else errors)
	quit(0 if errors.is_empty() else 1)
