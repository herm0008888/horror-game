extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var house := load("res://scenes/horror/house_layout.tscn").instantiate() as Node3D
	root.add_child(house)
	house.get_node("Lighting").set_normal_lighting(true)
	house.set_process(false)
	house.set_physics_process(false)
	var player := house.get_node("Player") as CharacterBody3D
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)
	house.get_node("HUD").hide()
	for node in house.get_children():
		if node is Label3D: node.visible=false
	var camera := Camera3D.new()
	house.add_child(camera)
	camera.fov=80
	camera.current=true
	var shots := [
		["cell",Vector3(5.1,-1.8,13.1),Vector3(7.2,-2.1,14.9)],
		["store",Vector3(4.8,-1.8,4.8),Vector3(1.5,-2.1,1.1)],
		["boiler",Vector3(10.0,-1.8,4.9),Vector3(7.0,-2.0,0.8)],
		["workshop",Vector3(12.8,-1.8,6.0),Vector3(14.6,-2.0,1.2)]
	]
	for shot in shots:
		camera.position=shot[1]
		camera.look_at(shot[2])
		for i in range(12): await process_frame
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://../basement-finished-%s.png" % shot[0])
	print("HOUSE_SURFACES_VISUAL_CHECK DONE")
	quit()
