extends SceneTree
var car: RigidBody3D
var scene: Node3D
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("run")
func wait_frames(count: int) -> void:
	for i in range(count): await physics_frame
func check(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
func run() -> void:
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	car = scene.get_node("Car")
	await wait_frames(180)
	print("REST ", car.position, " velocity ", car.linear_velocity)
	check(car.position.y > 0.25 and car.position.y < 1.0, "Suspension did not settle")
	Input.action_press("accelerate")
	await wait_frames(360)
	print("ACCELERATION ", car.linear_velocity.length()*3.6)
	check(car.linear_velocity.length() > 10.0, "Acceleration failed")
	Input.action_press("steer_left",0.7)
	Input.action_press("handbrake")
	await wait_frames(40)
	Input.action_release("handbrake")
	await wait_frames(80)
	print("DRIFT ", car.drift_amount, " yaw ", car.angular_velocity.y, " position ", car.position)
	check(absf(car.angular_velocity.y) > 0.1, "Steering did not rotate vehicle")
	check(car.position.y < 2.0, "Vehicle launched off ground")
	if DisplayServer.get_name() != "headless":
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../preview.png")
	Input.action_release("accelerate")
	Input.action_release("steer_left")
	Input.action_press("reset_car")
	await wait_frames(2)
	Input.action_release("reset_car")
	await wait_frames(120)
	check(car.position.distance_to(scene.get_node("Spawn").position) < 1.0, "Reset failed")
	Input.action_press("brake")
	await wait_frames(240)
	check(car.linear_velocity.dot(-car.global_basis.z) < -2.0, "Reverse failed")
	Input.action_release("brake")
	print("TEST_RESULT ", "PASS" if failures.is_empty() else failures)
	quit(0 if failures.is_empty() else 1)
