extends SceneTree
const OUT="C:/Users/hersv/Documents/Codex/2026-10-27/github-plugin-github-openai-curated-remote/outputs/"
func _initialize(): call_deferred("run")
func run():
	root.mode=Window.MODE_WINDOWED
	root.size=Vector2i(1280,800)
	var h=load("res://scenes/horror/house_layout.tscn").instantiate()
	h.process_mode=Node.PROCESS_MODE_DISABLED
	root.add_child(h)
	for n in h.find_children("*","CanvasLayer",true,false): n.hide()
	h.get_node("Lighting").set_normal_lighting(true)
	var cam=Camera3D.new()
	h.add_child(cam)
	cam.current=true
	cam.fov=82
	var views=[
		["master",Vector3(5.3,5.05,5.3),Vector3(2.5,4.5,2)],
		["east",Vector3(10.2,5.05,7.8),Vector3(14.2,4.3,9.7)],
		["south",Vector3(7.5,5.05,14.7),Vector3(12.1,4.4,14.3)],
		["bath",Vector3(10,5.05,3.5),Vector3(10,4.2,1.5)],
		["store",Vector3(3.3,4.95,14.5),Vector3(1.3,4.4,14.1)],
		["landing",Vector3(5,5.05,10.8),Vector3(8.5,4.8,7.3)],
		["secret",Vector3(-.6,4.15,5),Vector3(-.6,4.1,12)],
		["cell-repair",Vector3(5.4,-2.3,14.6),Vector3(4,-2.9,15.2)],
		["closet",Vector3(11.3,1.65,5.6),Vector3(10.9,1.2,2.8)]]
	for v in views:
		cam.position=v[1]
		cam.look_at(v[2])
		if h.has_node("HouseVisibility"): h.get_node("HouseVisibility").refresh(cam,true)
		for i in range(6): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT+"upgrade-"+v[0]+".png")
	h.free()
	quit()

