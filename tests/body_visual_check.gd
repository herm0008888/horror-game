extends SceneTree
func _initialize() -> void: call_deferred("run")
func find_skeleton(n: Node) -> Skeleton3D:
	if n is Skeleton3D: return n
	for c in n.get_children():
		var found := find_skeleton(c)
		if found: return found
	return null
func run() -> void:
	var scene := Node3D.new()
	root.add_child(scene)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.035,0.041,0.043)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.65,0.70,0.72)
	env.environment.ambient_light_energy = 0.65
	scene.add_child(env)
	var figure := load("res://scenes/horror/figure_visual.tscn").instantiate() as Node3D
	figure.scale = Vector3.ONE*1.28
	figure.rotation.y = PI
	scene.add_child(figure)
	var skeleton := find_skeleton(figure)
	var bones := {}
	var rest := {}
	for i in range(skeleton.get_bone_count()):
		bones[skeleton.get_bone_name(i)] = i
		rest[skeleton.get_bone_name(i)] = skeleton.get_bone_pose_rotation(i)
	var light := DirectionalLight3D.new()
	light.rotation_degrees=Vector3(-25,-35,0)
	light.light_energy=1.5
	scene.add_child(light)
	var camera := Camera3D.new()
	scene.add_child(camera)
	camera.position=Vector3(.4,1.55,4.7)
	camera.look_at(Vector3(0,1.36,0))
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=3.4
	camera.current=true
	var motion: Node = load("res://scripts/horror/haunted_motion.gd").new()
	scene.add_child(motion)
	for i in range(120):
		if i>15: motion.animate(1.0/60.0,true,true,figure,skeleton,bones,rest)
		await process_frame
		if i in [15,65,110] and DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://../body-game-%s.png" % i)
	print("BODY_VISUAL_CHECK PASS")
	quit()


