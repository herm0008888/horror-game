extends SceneTree
var errors: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	if not ok: errors.append(label)
func run() -> void:
	set_meta("creature_situation",1)
	var scene := load("res://scenes/horror/test_area.tscn").instantiate() as Node3D
	root.add_child(scene)
	current_scene = scene
	for i in range(5): await physics_frame
	var player: CharacterBody3D = scene.get_node("Player")
	var enemy: CharacterBody3D = scene.get_node("Visitation")
	player.set_physics_process(false)
	enemy.set_physics_process(false)
	var corner: Node = enemy.corner
	corner.recent_corners.clear()
	var covers := [Vector3(-5,0,0),Vector3(5,0,0),Vector3(-5,0,-7),Vector3(5,0,-7)]
	for cover in covers:
		enemy.position = cover + Vector3(-1.4,0.05,-1.5)
		enemy.figure.rotation.y = PI
		player.position = cover + Vector3(0,0.05,5)
		enemy.last_seen = player.position
		enemy.has_seen_player = true
		corner.active = false
		corner.holding = false
		corner.cooldown = 0
		corner.lean = 0
		corner.stare_cooldown = 100
		var before: int = corner.peek_count
		var maximum: float = 0
		for frame in range(35):
			corner.tick(1.0/60.0,false)
			maximum = maxf(maximum,corner.lean)
		check(corner.peek_count == before+1, "Peeks at each distinct covered corner")
		check(maximum > 0.9, "Fast full lean")
		check(not corner.active and corner.speed_factor() > 0, "Continues chase within half a second")
		corner.cooldown = 0
		corner.tick(1.0/60.0,false)
		check(not corner.active, "Doesn't spam same corner")
	print("QUICK_CORNER_PEEK_TEST ","PASS" if errors.is_empty() else errors," peeks=",corner.peek_count)
	quit(0 if errors.is_empty() else 1)
