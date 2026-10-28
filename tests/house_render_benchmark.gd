extends SceneTree
## Same camera/light state, before/after culling. Run windowed without vsync.
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.mode=Window.MODE_WINDOWED
	root.size=Vector2i(1280,720)
	root.content_scale_size=Vector2i.ZERO
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps=0
	var start:=Time.get_ticks_msec()
	var house: Node3D=load("res://scenes/horror/house_layout.tscn").instantiate()
	house.process_mode=Node.PROCESS_MODE_DISABLED
	root.add_child(house)
	for node in house.find_children("*","CanvasLayer",true,false): node.hide()
	for node in house.find_children("*","Label3D",true,false): node.hide()
	var camera:=Camera3D.new()
	house.add_child(camera)
	camera.current=true
	camera.fov=80
	print("LOAD_MS ",Time.get_ticks_msec()-start)
	var views: Array=[
		["cell",Vector3(5.1,-1.8,13.1),Vector3(7.2,-2.1,14.9)],
		["workshop",Vector3(12.8,-1.8,6),Vector3(14.6,-2,1.2)],
		["living",Vector3(13.8,1.7,12.65),Vector3(10.1,0.9,14.7)],
		["kitchen",Vector3(5.2,1.7,7.55),Vector3(8,0.95,2.5)],
		["doorway",Vector3(6,1.6,11.5),Vector3(9,1.3,9)],
		["stairs",Vector3(2.9,1.5,10),Vector3(3,2.2,6)]
	]
	var results: Array=[]
	for normal in [false,true]:
		house.get_node("Lighting").set_normal_lighting(normal)
		for view in views:
			camera.position=view[1]
			camera.look_at(view[2])
			for enabled in [false,true]:
				root.use_occlusion_culling=enabled
				for i in range(30): await process_frame
				var samples: Array[float]=[]
				var calls:=0.0
				var primitives:=0.0
				for i in range(60):
					var tick:=Time.get_ticks_usec()
					await process_frame
					samples.append((Time.get_ticks_usec()-tick)/1000.0)
					calls+=RenderingServer.viewport_get_render_info(root.get_viewport_rid(),RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE,RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME)
					primitives+=RenderingServer.viewport_get_render_info(root.get_viewport_rid(),RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE,RenderingServer.VIEWPORT_RENDER_INFO_PRIMITIVES_IN_FRAME)
				samples.sort()
				var item: Dictionary={"view":view[0],"normal":normal,"culling":enabled,"median_ms":samples[30],"p95_ms":samples[57],"draw_calls":calls/60.0,"primitives":primitives/60.0}
				results.append(item)
				print(JSON.stringify(item))
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://../perf_%s_%s_%s.png"%[view[0],str(normal),str(enabled)])
	var file:=FileAccess.open("res://../render_benchmark.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(results,"  "))
	house.free()
	await process_frame
	quit()
