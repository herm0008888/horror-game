extends SceneTree
var errors: Array[String] = []
func _initialize() -> void: call_deferred("run")
func press_l(echo: bool = false) -> void:
	var key := InputEventKey.new()
	key.physical_keycode=KEY_L
	key.keycode=KEY_L
	key.pressed=true
	key.echo=echo
	Input.parse_input_event(key)
func run() -> void:
	var house := load("res://scenes/horror/house_layout.tscn").instantiate() as Node3D
	root.add_child(house)
	house.set_process(false)
	var player := house.get_node("Player") as CharacterBody3D
	player.set_physics_process(false)
	var lighting: Node = house.get_node("Lighting")
	await process_frame
	if lighting.normal_lighting: errors.append("Default is not horror lighting")
	if not lighting.horror_lights.visible: errors.append("Horror fixtures disabled")
	for node in house.get_children():
		if node is OmniLight3D and node.visible: errors.append("Flat work lights visible in horror mode")
	press_l()
	await process_frame
	if not lighting.normal_lighting or lighting.horror_lights.visible: errors.append("L did not enable normal mode")
	if not is_equal_approx(lighting.environment.environment.ambient_light_energy,0.75): errors.append("Normal ambient was not restored")
	for node in house.get_children():
		if node is OmniLight3D and not node.visible: errors.append("Normal work light missing")
	press_l(true)
	await process_frame
	if not lighting.normal_lighting: errors.append("Held key toggled repeatedly")
	press_l()
	await process_frame
	if lighting.normal_lighting or not lighting.horror_lights.visible: errors.append("Second L did not restore horror")
	if lighting.environment.environment.ambient_light_energy>=0.75: errors.append("Horror ambient too bright")
	print("HOUSE_LIGHTING_TOGGLE_TEST ","PASS" if errors.is_empty() else errors)
	if DisplayServer.get_name()!="headless":
		house.get_node("HUD").hide()
		for node in house.get_children():
			if node is Label3D: node.visible=false
		var camera := Camera3D.new()
		house.add_child(camera)
		camera.fov=80
		camera.current=true
		for data in [["hall",Vector3(6,1.6,12),Vector3(6,1.35,6)],["basement",Vector3(6,-1.8,14),Vector3(5.2,-2.0,11.5)],["stairs",Vector3(2.9,1.5,10),Vector3(3,2.2,6)]]:
			camera.position=data[1]
			camera.look_at(data[2])
			for normal in [false,true]:
				lighting.set_normal_lighting(normal)
				for i in range(8): await process_frame
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://../lighting-%s-%s.png" % [data[0],"normal" if normal else "horror"])
	quit(0 if errors.is_empty() else 1)
