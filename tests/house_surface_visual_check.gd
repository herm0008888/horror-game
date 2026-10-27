extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var house := load("res://scenes/horror/house_layout.tscn").instantiate() as Node3D
	root.add_child(house)
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
		["hall",Vector3(6,1.6,12),Vector3(6,1.35,6)],
		["basement",Vector3(6,-1.8,14),Vector3(5.2,-2.0,11.5)],
		["stairs",Vector3(2.9,1.5,10),Vector3(3.0,2.2,6.0)]
	]
	for shot in shots:
		camera.position=shot[1]
		camera.look_at(shot[2])
		for i in range(12): await process_frame
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://../house-surfaces-%s.png" % shot[0])
	print("HOUSE_SURFACES_VISUAL_CHECK DONE")
	quit()
