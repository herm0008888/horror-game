extends SceneTree
var errors: Array[String] = []
func _initialize() -> void: call_deferred("run")
func run() -> void:
	set_meta("creature_situation", 4)
	var scene := load("res://scenes/horror/test_area.tscn").instantiate() as Node3D
	root.add_child(scene)
	current_scene = scene
	for i in range(5): await physics_frame
	var player: CharacterBody3D = scene.get_node("Player")
	var enemy: CharacterBody3D = scene.get_node("Visitation")
	player.set_physics_process(false)
	enemy.set_physics_process(false)
	player.capture(enemy)
	var scare: Node = player.get_node("Jumpscare")
	scare.set_process(false)
	if not scare.camera.current or player.camera.current: errors.append("Capture did not switch camera immediately")
	if not player.get_node("Caught").playing: errors.append("Impact sound delayed")
	scare._process(0.12)
	var open_immediately := false
	for mesh in scare.mesh_nodes:
		var shape: int = mesh.find_blend_shape_by_name("Scream")
		if shape >= 0 and mesh.get_blend_shape_value(shape) > 0.95: open_immediately = true
	if not open_immediately: errors.append("Mouth did not open during the initial lunge")
	var offset: Vector3 = scare.camera.global_position - scare.face
	if offset.length() > 1.0: errors.append("Initial recoil loses the close-up")
	for fps in [30, 60, 120]:
		scare.elapsed = 0.0
		scare.dead = false
		scare.black.color.a = 0.0
		scare._process(0.0)
		var previous: Vector3 = scare.shake_pivot.position
		for frame in range(int(float(fps) * 1.26)):
			scare._process(1.0 / float(fps))
			if scare.elapsed > 0.28 and scare.elapsed < 0.56 and previous.distance_to(scare.shake_pivot.position) < 0.0005:
				errors.append("Static frame during attack at %s fps" % fps)
			previous = scare.shake_pivot.position
		if not scare.dead or scare.black.color.a < 0.99: errors.append("Attack did not finish at the original timing")
	if DisplayServer.get_name() != "headless":
		scare.elapsed = 0.0
		scare.dead = false
		scare.black.color.a = 0.0
		scare._process(0.055)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../fast-jumpscare.png")
	print("CONTINUOUS_JUMPSCARE_TEST ", "PASS" if errors.is_empty() else errors)
	quit(0 if errors.is_empty() else 1)
