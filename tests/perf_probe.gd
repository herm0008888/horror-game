extends SceneTree
const OUT="C:/Users/hersv/Documents/Codex/2026-10-27/github-plugin-github-openai-curated-remote/work/"
func _initialize(): call_deferred("run")
func run():
	root.mode=Window.MODE_WINDOWED
	root.size=Vector2i(1280,720)
	root.content_scale_size=Vector2i.ZERO
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps=0
	var tag="after" if "after" in OS.get_cmdline_user_args() else "before"
	var start=Time.get_ticks_msec()
	var house=load("res://scenes/horror/house_layout.tscn").instantiate()
	house.process_mode=Node.PROCESS_MODE_DISABLED
	root.add_child(house)
	for node in house.find_children("*","CanvasLayer",true,false): node.hide()
	for node in house.find_children("*","Label3D",true,false): node.hide()
	var camera=Camera3D.new()
	house.add_child(camera)
	camera.current=true
	camera.fov=80
	var inventory={"meshes":0,"array_meshes":0,"surfaces":0,"lod_surfaces":0,"shadow_lights":0,"occluders":0}
	var groups={}
	for n in house.find_children("*","MeshInstance3D",true,false):
		inventory.meshes+=1
		if n.mesh is ArrayMesh:
			inventory.array_meshes+=1
			var imported=ImporterMesh.from_mesh(n.mesh)
			for s in range(imported.get_surface_count()):
				inventory.surfaces+=1
				if imported.get_surface_lod_count(s)>0: inventory.lod_surfaces+=1
		var parent=n.get_parent()
		while parent!=house and not parent.has_meta("asset_id") and not parent.has_meta("source"): parent=parent.get_parent()
		var key=str(parent.get_path())
		groups[key]=groups.get(key,0)+1
	for n in house.find_children("*","Light3D",true,false):
		if n.shadow_enabled: inventory.shadow_lights+=1
	inventory.occluders=house.find_children("*","OccluderInstance3D",true,false).size()
	print("INVENTORY ",JSON.stringify(inventory))
	FileAccess.open(OUT+"mesh_groups_"+tag+".json",FileAccess.WRITE).store_string(JSON.stringify(groups,"  "))
	var views=[
		["cell",Vector3(5.1,-1.8,13.1),Vector3(7.2,-2.1,14.9)],
		["workshop",Vector3(12.8,-1.8,6),Vector3(14.6,-2,1.2)],
		["living",Vector3(13.8,1.7,12.65),Vector3(10.1,.9,14.7)],
		["kitchen",Vector3(5.2,1.7,7.55),Vector3(8,.95,2.5)],
		["doorway",Vector3(6,1.6,11.5),Vector3(9,1.3,9)],
		["stairs",Vector3(2.9,1.5,10),Vector3(3,2.2,6)]]
	var result={"load_ms":Time.get_ticks_msec()-start,"inventory":inventory,"views":[]}
	for normal in [false,true]:
		house.get_node("Lighting").set_normal_lighting(normal)
		for view in views:
			camera.position=view[1]
			camera.look_at(view[2])
			if house.has_node("HouseVisibility"): house.get_node("HouseVisibility").refresh(camera,true)
			for i in range(20): await process_frame
			var times=[]
			var calls=0.0
			var triangles=0.0
			for i in range(60):
				var tick=Time.get_ticks_usec()
				await process_frame
				times.append((Time.get_ticks_usec()-tick)/1000.0)
				calls+=RenderingServer.viewport_get_render_info(root.get_viewport_rid(),RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE,RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME)
				triangles+=RenderingServer.viewport_get_render_info(root.get_viewport_rid(),RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE,RenderingServer.VIEWPORT_RENDER_INFO_PRIMITIVES_IN_FRAME)
			times.sort()
			var row={"view":view[0],"normal":normal,"median_ms":times[30],"p95_ms":times[57],"draw_calls":calls/60,"primitives":triangles/60}
			result.views.append(row)
			print(JSON.stringify(row))
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OUT+"perf_"+tag+"_"+str(view[0])+"_"+str(normal)+".png")
	FileAccess.open(OUT+"performance_"+tag+".json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	house.free()
	await process_frame
	quit()

