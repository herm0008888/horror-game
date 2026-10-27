extends SceneTree
var errors: Array[String] = []
func _initialize() -> void: call_deferred("run")
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func check(ok: bool, label: String) -> void:
	if not ok: errors.append(label)
func run() -> void:
	set_meta("creature_situation",0)
	var scene := load("res://scenes/horror/test_area.tscn").instantiate() as Node3D
	root.add_child(scene)
	current_scene = scene
	await frames(4)
	for i in range(5):
		var key := InputEventKey.new()
		key.physical_keycode = KEY_1+i
		key.pressed = true
		scene._unhandled_input(key)
		await frames(5)
		scene = current_scene
		check(scene.current_situation == i, "Number key selects situation %s" % (i+1))
		var player: CharacterBody3D = scene.get_node("Player")
		var enemy: CharacterBody3D = scene.get_node("Visitation")
		player.set_physics_process(false)
		if i == 0:
			var distance := enemy.position.distance_to(player.position)
			await frames(120)
			check(enemy.position.distance_to(player.position) < distance-2.0, "Visible player is chased instead of retreating to cover")
			check(not enemy.corner.active, "No tactical retreat while player is visible")
		if i == 1:
			await frames(55)
			check(enemy.corner.peek_count > 0, "Corner scenario peeks only at current cover")
		if i == 3:
			check(scene.get_node("Environment").environment.ambient_light_energy < 0.1, "Dark scenario has distinct lighting")
			check(not player.has_flashlight and scene.has_node("FlashlightPickup"), "Dark scenario starts with pickup")
		enemy.set_physics_process(false)
		if DisplayServer.get_name() != "headless":
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://../situation-%s.png" % (i+1))
	print("SITUATIONS_TEST ", "PASS" if errors.is_empty() else errors)
	quit(0 if errors.is_empty() else 1)
