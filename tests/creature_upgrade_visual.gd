extends SceneTree
const OUT="C:/Users/hersv/Documents/Codex/2026-10-27/github-plugin-github-openai-curated-remote/outputs/"
func _initialize(): call_deferred("run")
func run():
	root.mode=Window.MODE_WINDOWED
	root.size=Vector2i(1280,800)
	var h=load("res://scenes/horror/house_layout.tscn").instantiate()
	h.process_mode=Node.PROCESS_MODE_DISABLED
	root.add_child(h)
	var e=h.get_node("Visitation")
	var p=h.get_node("Player")
	for n in h.find_children("*","CanvasLayer",true,false): n.hide()
	var stage=Node3D.new()
	root.add_child(stage)
	e.reparent(stage)
	e.process_mode=Node.PROCESS_MODE_DISABLED
	h.get_node("Lighting").set_normal_lighting(true)
	e.position=Vector3.ZERO
	e.figure.position=Vector3.ZERO
	e.figure.rotation=Vector3.ZERO
	h.visible=false
	var light=DirectionalLight3D.new()
	light.rotation_degrees=Vector3(-30,-10,0)
	light.light_energy=.8
	stage.add_child(light)
	var cam=Camera3D.new()
	stage.add_child(cam)
	cam.current=true
	cam.position=Vector3(0,1.5,-3)
	cam.look_at(Vector3(0,1.15,0))
	for hunting in [false,true]:
		for i in range(24):
			e.motion.animate(1.0/60,true,hunting,e.figure,e.pose_skeleton,e.pose_bones,e.pose_rest_rotations)
		for i in range(4): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT+"creature-"+("run" if hunting else "walk")+".png")
	cam.position=Vector3(0,1.85,-1.4)
	cam.look_at(Vector3(0,1.8,-.2))
	for i in range(4): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+"creature-face.png")
	p.capture(e)
	var scare=p.get_node("Jumpscare")
	scare.set_process(false)
	for t in [.04,.12,.35,.65]:
		scare.elapsed=0
		scare._process(t)
		for i in range(4): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT+"jumpscare-"+str(t)+".png")
	print("CREATURE_UPGRADE_VISUAL_COMPLETE")
	h.free()
	stage.free()
	quit()

