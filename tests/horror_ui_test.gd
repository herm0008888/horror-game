extends SceneTree
var failures: Array[String]=[]
func _initialize() -> void: call_deferred("run")
func press_l() -> void:
	var event:=InputEventKey.new()
	event.physical_keycode=KEY_L
	event.pressed=true
	Input.parse_input_event(event)
func run() -> void:
	var house:=load("res://scenes/horror/house_layout.tscn").instantiate() as Node3D
	root.add_child(house)
	house.set_process(false)
	var player:=house.get_node("Player") as CharacterBody3D
	player.set_physics_process(false)
	var effects: Node=house.get_node("HorrorUI")
	await process_frame
	if not effects.overlay.visible or not effects.effects_enabled: failures.append("Horror UI missing on start")
	if effects.overlay.mouse_filter!=Control.MOUSE_FILTER_IGNORE: failures.append("Overlay blocks input")
	press_l()
	await process_frame
	if effects.overlay.visible or effects.is_processing(): failures.append("Normal mode did not disable overlay")
	press_l()
	await process_frame
	if not effects.overlay.visible or not effects.is_processing(): failures.append("Horror mode did not restore overlay")
	effects.elapsed=10.1
	effects._process(0.016)
	if effects.interference_left<=0: failures.append("Missing rare interference")
	if DisplayServer.get_name()!="headless":
		house.get_node("HUD").hide()
		for node in house.get_children():
			if node is Label3D: node.hide()
		var camera:=Camera3D.new()
		house.add_child(camera)
		camera.position=Vector3(6,1.6,12)
		camera.look_at(Vector3(6,1.35,6))
		camera.fov=80
		camera.current=true
		for i in range(12):await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../horror-ui-preview.png")
	print("HORROR_UI_TEST ","PASS" if failures.is_empty() else failures)
	quit(0 if failures.is_empty() else 1)
