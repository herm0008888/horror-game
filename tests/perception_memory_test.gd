extends SceneTree
var errors: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value: errors.append(message)
func run() -> void:
	set_meta("creature_situation", 0)
	var scene := load("res://scenes/horror/test_area.tscn").instantiate() as Node3D
	root.add_child(scene)
	current_scene = scene
	for i in range(5): await physics_frame
	var player: CharacterBody3D = scene.get_node("Player")
	var enemy: CharacterBody3D = scene.get_node("Visitation")
	player.set_physics_process(false)
	enemy.set_physics_process(false)
	enemy.position = Vector3(3.6, 0.05, -4.0)
	enemy.figure.rotation = Vector3(0, PI, 0)
	player.position = Vector3(3.4, 0.05, 3.0)
	enemy.corner.cooldown = 0.0
	enemy.corner.stare_cooldown = 100.0
	await physics_frame
	enemy._physics_process(1.0 / 60.0)
	check(enemy.sees_player, "Visible player must be detected")
	var remembered: Vector3 = enemy.last_seen
	# Cross behind the solid block, then move farther away without footsteps.
	player.position = Vector3(6.7, 0.05, 2.0)
	await physics_frame
	enemy._physics_process(1.0 / 60.0)
	check(not enemy.sees_player, "Wall must block detection")
	check(enemy.state == "INVESTIGATE", "Sight loss must enter investigation")
	check(enemy.last_seen.is_equal_approx(remembered), "Last seen must remain fixed")
	check(enemy.corner.active, "Pursuit must select an upcoming corner, not only a nearby spawn")
	check(enemy.global_position.distance_to(enemy.corner.destination) > 1.0, "Corner should be approached from normal chase distance")
	var original_focus: Vector3 = enemy.attention_target()
	var corner_destination: Vector3 = enemy.corner.destination
	player.position = Vector3(7.2, 0.05, 3.0)
	await physics_frame
	enemy._physics_process(1.0 / 60.0)
	check(not enemy.sees_player and enemy.last_seen.is_equal_approx(remembered), "Silent movement behind cover must not update memory")
	check(enemy.attention_target().is_equal_approx(original_focus), "Head and eyes must not track hidden movement")
	check(enemy.corner.destination.is_equal_approx(corner_destination), "Hidden movement must not change chosen corner")
	# Walk the real AI into the selected peek while the player remains occluded.
	enemy.set_physics_process(true)
	var reached_peek := false
	for i in range(300):
		await physics_frame
		if enemy.corner.holding:
			reached_peek = true
			break
	enemy.set_physics_process(false)
	check(reached_peek, "Ordinary pursuit must actually reach and perform the peek")
	check(not enemy.sees_player, "Covered player must still be unknown at start of peek")
	# A heard sound changes the clue once; silence after it does not follow the player.
	var sound := Vector3(3.0, 0.05, 2.5)
	enemy.hear_noise(sound, 20.0)
	check(enemy.last_seen.is_equal_approx(sound) and enemy.state == "INVESTIGATE", "Audible sound must set a location clue")
	enemy.hear_noise(Vector3(100, 0, 100), 1.0)
	check(enemy.last_seen.is_equal_approx(sound), "Inaudible sound must not update memory")
	# Prior discovery does not grant 360-degree vision.
	enemy.position = Vector3(0, 0.05, 0)
	enemy.figure.rotation = Vector3.ZERO
	player.position = Vector3(0, 0.05, 6)
	await physics_frame
	check(not enemy.can_see_player(), "Previously seen player behind enemy must stay unseen")
	enemy.figure.rotation.y = PI
	await physics_frame
	check(enemy.can_see_player(), "Player can be reacquired through genuine unobstructed sight")
	enemy.begin_search()
	enemy.search_left = 0.001
	player.position = Vector3(40, 0, 40)
	enemy.corner.active = false
	enemy.corner.holding = false
	enemy._physics_process(0.02)
	check(enemy.state == "PATROL" and not enemy.has_seen_player, "Failed search must eventually return to patrol")
	print("PERCEPTION_MEMORY_TEST ", "PASS" if errors.is_empty() else errors)
	quit(0 if errors.is_empty() else 1)
