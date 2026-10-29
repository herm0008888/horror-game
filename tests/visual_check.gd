extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var scene := load("res://scenes/main.tscn").instantiate() as Node3D
	root.add_child(scene)
	current_scene = scene
	for i in range(90): await process_frame
	var start := Time.get_ticks_msec()
	for i in range(120): await process_frame
	print("RENDER_AVERAGE_FPS ", 120000.0 / (Time.get_ticks_msec() - start))
	print("DRAW_CALLS ", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	print("VIDEO_MB ", Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../preview.png")
	quit()
