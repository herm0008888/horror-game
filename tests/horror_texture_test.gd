extends SceneTree
func _initialize() -> void: call_deferred("run")
func render_frames(count: int) -> void:
	for i in range(count): await process_frame
	await RenderingServer.frame_post_draw
func run() -> void:
	var scene := load("res://scenes/horror/main.tscn").instantiate() as Node3D
	root.add_child(scene)
	current_scene = scene
	var player: Node3D = scene.get_node("Player")
	await render_frames(10)
	paused = true
	var camera: Camera3D = player.get_node("Head/Camera")
	var original := camera.global_transform
	await render_frames(3)
	var baseline := root.get_texture().get_image().get_data()
	await render_frames(15)
	var stationary := root.get_texture().get_image().get_data()
	camera.global_position += Vector3(0.35,0,0)
	camera.rotate_y(0.15)
	await render_frames(3)
	camera.global_transform = original
	await render_frames(5)
	var returned := root.get_texture().get_image()
	var restored := returned.get_data()
	var changed_stationary := 0
	var changed_restored := 0
	for i in range(baseline.size()):
		if abs(baseline[i] - stationary[i]) > 2: changed_stationary += 1
		if abs(baseline[i] - restored[i]) > 2: changed_restored += 1
	var stationary_ratio := float(changed_stationary) / baseline.size()
	var restored_ratio := float(changed_restored) / baseline.size()
	returned.save_png("res://../horror-stable-preview.png")
	var passed := stationary_ratio < 0.001 and restored_ratio < 0.01
	print("TEXTURE_STABILITY ", "PASS" if passed else "FAIL", " stationary=", stationary_ratio, " restored=", restored_ratio)
	paused = false
	quit(0 if passed else 1)
