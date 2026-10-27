extends SceneTree
var failures: Array[String] = []
func _initialize() -> void:
	Engine.max_fps = 60
	call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value: failures.append(message)
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func run() -> void:
	var scene := load("res://scenes/horror/rundown_house_test.tscn").instantiate() as Node3D
	root.add_child(scene)
	current_scene = scene
	await frames(10)
	var player: CharacterBody3D = scene.get_node("Player")
	check(player.is_on_floor(), "Initial player spawn must stand on the hall floor")
	check(scene.room_regions.size() == 14, "All 14 rooms must be present")
	check(scene.get_meta("prop_count",0) > 75, "Scene must have complete furnishing")
	player.set_physics_process(false)
	# Check floor, door collision, and an unobstructed entrance into every room.
	for marker in scene.get_node("RoomMarkers").get_children():
		var center: Vector3 = marker.position
		var side := signf(center.x)
		var entry := Vector3(side * 2.25, center.y, center.z)
		var floor_query := PhysicsRayQueryParameters3D.create(entry + Vector3.UP * 0.15, entry - Vector3.UP * 0.4,1)
		check(not scene.get_world_3d().direct_space_state.intersect_ray(floor_query).is_empty(), "Missing floor at " + marker.name)
		var door: Node3D = scene.get_node("DoorsAndHatch").get_node(String(marker.name) + "Door")
		var from := Vector3(0, center.y+1.1, center.z)
		var to := Vector3(side*2.4, center.y+1.1, center.z)
		var query := PhysicsRayQueryParameters3D.create(from,to,1)
		var closed_hit := scene.get_world_3d().direct_space_state.intersect_ray(query)
		check(not closed_hit.is_empty(), "Closed door doesn't block " + marker.name)
		door.set_open(true)
	await create_timer(0.8).timeout
	await frames(3)
	for marker in scene.get_node("RoomMarkers").get_children():
		var center: Vector3 = marker.position
		var side := signf(center.x)
		var query := PhysicsRayQueryParameters3D.create(Vector3(0,center.y+1.1,center.z),Vector3(side*2.4,center.y+1.1,center.z),1)
		check(scene.get_world_3d().direct_space_state.intersect_ray(query).is_empty(), "Open doorway obstructed at " + marker.name)
	# Real input traverses both sloping stair colliders, not teleported markers.
	player.position = Vector3(0,0.05,0.6)
	player.rotation = Vector3.ZERO
	player.velocity = Vector3.ZERO
	player.set_physics_process(true)
	Input.action_press("move_forward")
	await frames(290)
	Input.action_release("move_forward")
	await frames(10)
	print("STAIR_UP position=",player.position)
	check(player.position.y > 3.2 and player.position.z < -7.7, "Stairs to upper floor must be walkable")
	# Descend from the ground floor rear landing to the basement.
	player.position = Vector3(0,0.05,-8.2)
	player.rotation.y = PI
	player.velocity = Vector3.ZERO
	Input.action_press("move_forward")
	await frames(290)
	Input.action_release("move_forward")
	await frames(10)
	print("STAIR_DOWN position=",player.position)
	check(player.position.y < -3.2 and player.position.z > 0.0, "Basement stairs must be walkable")
	# The floor hatch must physically open and drop the player onto the cellar floor.
	player.position = Vector3(0,0.05,6.3)
	player.velocity = Vector3.ZERO
	await frames(8)
	check(player.position.y > -0.2, "Closed hatch must support the player")
	var hatch: Node3D = scene.get_node("DoorsAndHatch/FloorHatch")
	hatch.interact()
	await frames(100)
	check(player.is_on_floor() and player.position.y < -3.2, "Open hatch must drop to a safe basement landing")
	player.reset_position()
	await frames(8)
	check(player.position.y > -0.2 and player.position.z > 7.0, "R/reset must return to a safe entrance")
	print("FULL_HOUSE_TEST ","PASS" if failures.is_empty() else failures)
	quit(0 if failures.is_empty() else 1)
