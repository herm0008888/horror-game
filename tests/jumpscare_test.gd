extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	set_meta("creature_situation",4)
	var scene := load("res://scenes/horror/test_area.tscn").instantiate() as Node3D
	root.add_child(scene)
	current_scene = scene
	for i in range(5): await physics_frame
	var player: CharacterBody3D = scene.get_node("Player")
	var enemy: CharacterBody3D = scene.get_node("Visitation")
	enemy.set_physics_process(false)
	# Begin with a sideways tracked head; capture must reset it to the authored pose.
	enemy.figure.rotation.z = 0.3
	player.position.x = 1.2
	enemy.track_player_head(1.0/60.0)
	var editor_camera: Camera3D = enemy.get_node("Figure/JumpscareSetup/CameraShake/JumpscareCamera")
	var editor_transform := editor_camera.transform
	player.capture(enemy)
	var scare: Node = player.get_node("Jumpscare")
	await create_timer(0.55).timeout
	var offset: Vector3 = scare.camera.global_position-scare.face
	var centered: float = (-scare.camera.global_basis.z).dot(-offset.normalized())
	var frontal: float = offset.normalized().dot(scare.face_forward)
	var sideways: float = absf(offset.dot(scare.setup.global_basis.orthonormalized().x))
	var ok: bool = player.caught and not player.get_node("Caught").playing and offset.length() < 0.8 and centered > 0.995 and frontal > 0.99 and sideways < 0.025
	ok = ok and scare.camera == editor_camera and editor_camera.current and not player.camera.current
	ok = ok and editor_camera.transform.is_equal_approx(editor_transform) and absf(enemy.figure.rotation.z) < 0.001
	print("SCARE_FRAMING centered=",centered," frontal=",frontal," distance=",offset.length())
	var found := false
	var physical_interior := false
	for mesh in scare.mesh_nodes:
		var index: int = mesh.find_blend_shape_by_name("Scream")
		if index >= 0: found = mesh.get_blend_shape_value(index) > 0.9
		for surface in range(mesh.mesh.get_surface_count()):
			var material := mesh.get_active_material(surface) as ShaderMaterial
			if material and material.shader.resource_path.ends_with("mouth_interior.gdshader"): physical_interior = true
	ok = ok and found and physical_interior
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../silent-jumpscare.png")
	await create_timer(0.65).timeout
	var entry: Node3D = scare.setup.get_node("MouthEntry")
	var inside: Node3D = scare.setup.get_node("SwallowEnd")
	ok = ok and scare.phase in ["BITE","DEAD"] and scare.shake_pivot.position.distance_to(inside.position) < entry.position.distance_to(inside.position)*0.5
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../swallowed-camera.png")
	await create_timer(0.90).timeout
	ok = ok and scare.dead and scare.black.color.a > 0.95
	print("SILENT_JUMPSCARE_TEST ","PASS" if ok else "FAIL")
	quit(0 if ok else 1)
