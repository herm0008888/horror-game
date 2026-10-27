extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var scene := load("res://scenes/horror/main.tscn").instantiate() as Node3D
	root.add_child(scene)
	current_scene = scene
	var player: CharacterBody3D = scene.get_node("Player")
	var enemy: CharacterBody3D = scene.get_node("Visitation")
	player.set_physics_process(false)
	player.position = Vector3(50,0,50)
	var visited_ground := false
	var furthest_patrol := 0
	for frame in range(15000):
		await physics_frame
		furthest_patrol = maxi(furthest_patrol, enemy.patrol_index)
		if enemy.position.y < 0.25 and enemy.position.z > 0: visited_ground = true
		if frame % 2400 == 0: print("PATROL ", frame, " ", enemy.position, " target=", enemy.patrol_index)
	var opened_doors := 0
	for door in scene.get_node("House/Doors").get_children():
		if door.opened: opened_doors += 1
	var passed := visited_ground and opened_doors >= 6 and furthest_patrol >= 20
	print("PATROL_TEST ", "PASS" if passed else "FAIL", " ground=", visited_ground, " doors=", opened_doors, " furthest=", furthest_patrol)
	quit(0 if passed else 1)
