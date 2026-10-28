extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var h=load("res://scenes/horror/house_layout.tscn").instantiate()
	h.process_mode=Node.PROCESS_MODE_DISABLED
	root.add_child(h)
	var e=h.get_node("Visitation")
	print("FIGURE ",e.figure.get_path())
	var s=e.pose_skeleton
	for i in range(s.get_bone_count()): print("BONE ",i," ",s.get_bone_name(i)," parent ",s.get_bone_parent(i)," rest ",s.get_bone_global_rest(i).origin," basis ",s.get_bone_global_rest(i).basis.get_euler())
	for m in e.figure.find_children("*","MeshInstance3D",true,false):
		if not m.mesh: continue
		for i in range(m.mesh.get_surface_count()): print("SURFACE ",m.name," ",i," ",m.get_active_material(i).resource_name," ",m.mesh.surface_get_array_len(i) if m.mesh is ArrayMesh else 0)
	var stage=Node3D.new()
	root.add_child(stage)
	e.reparent(stage)
	e.position=Vector3.ZERO
	e.figure.position=Vector3.ZERO
	e.figure.rotation=Vector3.ZERO
	h.visible=false
	var light=DirectionalLight3D.new()
	light.rotation_degrees=Vector3(-25,20,0)
	light.light_energy=.7
	stage.add_child(light)
	var cam=Camera3D.new()
	stage.add_child(cam)
	cam.current=true
	cam.global_position=e.global_position+Vector3(0,1.4,-3.1)
	cam.look_at(e.global_position+Vector3(0,1.2,0))
	h.get_node("Lighting").set_normal_lighting(true)
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("C:/Users/hersv/Documents/Codex/2026-10-27/github-plugin-github-openai-curated-remote/work/creature-before.png")
	h.free()
	quit()

