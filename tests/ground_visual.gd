extends SceneTree
const OUT="C:/Users/hersv/Documents/Codex/2026-10-27/github-plugin-github-openai-curated-remote/outputs/"
func _initialize(): call_deferred("run")
func run():
	root.size=Vector2i(1440,900)
	var house=load("res://scenes/horror/house_layout.tscn").instantiate()
	house.process_mode=Node.PROCESS_MODE_DISABLED
	root.add_child(house)
	for n in house.find_children("*","CanvasLayer",true,false): n.hide()
	var camera=Camera3D.new()
	house.add_child(camera)
	camera.current=true
	camera.fov=85
	camera.near=.05
	house.get_node("Lighting").set_normal_lighting(true)
	var views=[
		["living",Vector3(13.8,1.7,12.65),Vector3(10.1,.9,14.7)],
		["kitchen",Vector3(5.2,1.7,7.55),Vector3(8,.95,2.5)],
		["kitchen-worktops",Vector3(10,1.65,2.9),Vector3(7.4,.95,.65)],
		["study",Vector3(3.45,1.65,4.85),Vector3(1.4,1,2.8)],
		["utility",Vector3(12.65,1.65,9.2),Vector3(14.3,.9,7.4)],
		["store",Vector3(2.3,1.65,12.5),Vector3(2.4,.9,15)],
		["hall",Vector3(11.3,1.65,9.6),Vector3(5.8,1.2,11.6)],
		["living-reverse",Vector3(7.8,1.65,13.4),Vector3(12.1,1,14.9)]
	]
	for view in views:
		camera.position=view[1]
		camera.look_at(view[2])
		for i in range(8): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT+"ground-floor-"+view[0]+".png")
	house.get_node("Lighting").set_normal_lighting(false)
	camera.position=Vector3(13.8,1.7,12.65)
	camera.look_at(Vector3(10.1,.9,14.7))
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+"ground-floor-horror.png")
	house.free()
	quit()
