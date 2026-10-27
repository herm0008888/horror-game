extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var scene := load("res://scenes/horror/main.tscn").instantiate() as Node3D
	root.add_child(scene)
	current_scene = scene
	var player: CharacterBody3D = scene.get_node("Player")
	var enemy: CharacterBody3D = scene.get_node("Visitation")
	enemy.set_physics_process(false)
	await physics_frame
	player.global_position = Vector3(0,0,6)
	enemy.global_position = Vector3(0,0,5)
	enemy.figure.rotation.y = PI
	var original_id := scene.get_instance_id()
	var initial_basis: Basis = player.camera.global_basis
	player.capture(enemy)
	for i in range(30): await physics_frame
	var correct: bool = player.caught and scene.get_node("Film/Overlay").caught and absf(player.camera.fov - 76.0) < 0.1
	correct = correct and player.camera.global_basis.is_equal_approx(initial_basis)
	if DisplayServer.get_name() != "headless":
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../horror-jumpscare.png")
	for i in range(160): await physics_frame
	correct = correct and current_scene.get_instance_id() != original_id
	print("CAPTURE_RESTART_TEST ", "PASS" if correct else "FAIL")
	quit(0 if correct else 1)
