extends SceneTree
var failures: Array[String]=[]
func _initialize() -> void: call_deferred("run")
func press(keycode: Key) -> void:
	var event:=InputEventKey.new()
	event.physical_keycode=keycode
	event.keycode=keycode
	event.device=0
	event.pressed=true
	root.push_input(event,true)
	await process_frame
	event=event.duplicate()
	event.pressed=false
	root.push_input(event,true)
	await physics_frame
func run() -> void:
	var house:=load("res://scenes/horror/house_layout.tscn").instantiate() as Node3D
	root.add_child(house)
	house.set_process(false)
	var player:=house.get_node("Player") as CharacterBody3D
	player.set_physics_process(false)
	var torch: Node=player.get_node("Camera/FlashlightRig")
	var lighting: Node=house.get_node("Lighting")
	player.position=Vector3(6,-3.39,14)
	player.camera.look_at(house.get_node("FlashlightPickup").global_position)
	for i in range(4):await physics_frame
	if torch.equipped or torch.beam.visible:failures.append("Flashlight available before pickup")
	if lighting.environment.environment.ambient_light_energy>0.15:failures.append("House remains too bright")
	var ray:=PhysicsRayQueryParameters3D.create(player.camera.global_position,player.camera.global_position-player.camera.global_basis.z*2.6,1,[player.get_rid()])
	var hit:=player.get_world_3d().direct_space_state.intersect_ray(ray)
	if hit.get("collider")!=house.get_node("FlashlightPickup"):failures.append("Pickup is blocked from the landing spot")
	await press(KEY_E)
	await process_frame
	await physics_frame
	if not torch.equipped or not torch.beam.visible:failures.append("Looking at flashlight and E did not equip it")
	if house.has_node("FlashlightPickup"):failures.append("Pickup remains after being taken")
	await press(KEY_F)
	await process_frame
	if torch.beam.visible or torch.spill.visible:failures.append("F did not switch flashlight off")
	await press(KEY_F)
	await process_frame
	if not torch.beam.visible:failures.append("Second F did not restore beam")
	await press(KEY_L)
	await process_frame
	if not lighting.normal_lighting or lighting.environment.environment.ambient_light_energy<0.7:failures.append("L lost normal work lighting")
	await press(KEY_L)
	await process_frame
	if lighting.normal_lighting:failures.append("L did not return to horror lighting")
	if DisplayServer.get_name()!="headless":
		house.get_node("HUD").hide()
		for node in house.get_children():
			if node is Label3D:node.hide()
		player.position=Vector3(6,0.02,12)
		player.camera.look_at(Vector3(6,1.35,6))
		for mode in ["off","on","normal"]:
			lighting.set_normal_lighting(mode=="normal")
			torch.set_switched_on(mode=="on")
			for i in range(10):await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://../dark-house-flashlight-%s.png" % mode)
	print("DARK_HOUSE_FLASHLIGHT_TEST ","PASS" if failures.is_empty() else failures)
	quit(0 if failures.is_empty() else 1)
