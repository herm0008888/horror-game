extends SceneTree
func _initialize() -> void: call_deferred("run")
func snapshot(path: String) -> void:
	for i in range(12): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
func run() -> void:
	var scene := load("res://scenes/horror/main.tscn").instantiate() as Node3D
	root.add_child(scene)
	current_scene = scene
	var player: CharacterBody3D = scene.get_node("Player")
	var enemy: CharacterBody3D = scene.get_node("Visitation")
	player.set_physics_process(false)
	enemy.set_physics_process(false)
	await snapshot("res://../house-hall.png")
	player.position = Vector3(-3.4,0.05,7.7)
	player.camera.look_at(Vector3(-5.2,0.65,4.0))
	await snapshot("res://../house-living.png")
	player.position = Vector3(3.3,0.05,7.8)
	player.camera.look_at(Vector3(7.0,1.0,2.2))
	await snapshot("res://../house-kitchen.png")
	player.position = Vector3(-3.6,3.25,8.1)
	player.camera.look_at(Vector3(-6.3,3.8,6.0))
	await snapshot("res://../house-bedroom.png")
	print("HOUSE_VISUAL_CHECK COMPLETE")
	quit()
