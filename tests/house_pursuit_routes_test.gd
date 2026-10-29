extends SceneTree
var failures:=0
func _initialize() -> void: call_deferred("run")
func run() -> void:
	Engine.max_fps=0
	var h: Node3D=load("res://scenes/horror/house_layout.tscn").instantiate()
	root.add_child(h)
	h.set_process(false)
	var p: CharacterBody3D=h.get_node("Player")
	p.set_physics_process(false)
	p.position=Vector3(100,0,100)
	var e: CharacterBody3D=h.get_node("Visitation")
	e.chase_speed=4.0
	for i in range(8): await physics_frame
	for data in [["living tables",Vector3(5.5,0,11),Vector3(14,0,13)],["kitchen furniture",Vector3(14,0,8),Vector3(6.5,0,4)],["basement up",Vector3(2.7,-3.39,11.1),Vector3(5.5,0,11)], ["upper up",Vector3(14,0,5.1),Vector3(5.5,3.4,11)],["upper down",Vector3(5.5,3.4,11),Vector3(14,0,5.1)],["basement down",Vector3(5.5,0,11),Vector3(2.7,-3.39,11.1)]]:
		e.position=data[1]
		e.velocity=Vector3.ZERO
		e.recovery_left=0.0
		e.stuck_time=0.0
		e.previous_position=e.position
		e.last_seen=data[2]
		e.hunt=999
		e.repath=0
		var reached:=false
		for frame in range(1500):
			await physics_frame
			if e.position.distance_to(data[2])<0.9:
				reached=true
				break
		print("PASS " if reached else "FAIL ",data[0]," ended=",e.position," target=",data[2])
		if not reached: failures+=1
	print("PURSUIT_ALL_ROUTES_TEST failures=",failures)
	h.free()
	await process_frame
	quit(1 if failures else 0)
