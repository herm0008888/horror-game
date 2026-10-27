extends SceneTree
var errors: Array[String] = []
func _initialize() -> void: call_deferred("run")
func run() -> void:
	set_meta("creature_situation",0)
	var scene := load("res://scenes/horror/test_area.tscn").instantiate() as Node3D
	root.add_child(scene)
	current_scene = scene
	for i in range(5): await physics_frame
	var player: CharacterBody3D = scene.get_node("Player")
	var enemy: CharacterBody3D = scene.get_node("Visitation")
	player.set_physics_process(false)
	enemy.set_physics_process(false)
	enemy.position = Vector3(3.6,0.05,-1.5)
	player.position = Vector3(5,0.05,5)
	var path: PackedVector3Array = enemy.plan_route(player.position)
	if path.is_empty(): errors.append("Route around cover is empty")
	else:
		if path[-1].distance_to(player.position) > 0.01: errors.append("Route doesn't end at player")
		var previous := enemy.position
		for point in path:
			if not enemy.clear_passage(previous,point): errors.append("Route clips cover")
			previous = point
	if not enemy.has_node("PathDebug"): errors.append("Missing visible route")
	enemy.position = Vector3(0,0.05,-5)
	enemy.figure.rotation.y = PI
	player.position = Vector3(0,0.05,8)
	enemy.route_path.clear()
	enemy.repath = 0
	enemy.state = "CHASE"
	enemy.hunt = 20
	enemy.last_seen = player.position
	enemy.has_seen_player = true
	enemy.set_physics_process(true)
	var captured := false
	for i in range(600):
		await physics_frame
		if player.caught:
			captured = true
			break
	if not captured: errors.append("Enemy failed to catch stationary player")
	print("PURSUIT_PATH_TEST ", "PASS" if errors.is_empty() else errors, " route=",path)
	quit(0 if errors.is_empty() else 1)
