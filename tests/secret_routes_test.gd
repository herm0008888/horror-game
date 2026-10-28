extends SceneTree
var h: Node3D
var p: CharacterBody3D
var failures:=0
func _initialize(): call_deferred("run")
func frames(n: int):
	for i in range(n): await physics_frame
func check(ok: bool,title: String):
	print("PASS " if ok else "FAIL ",title," ",p.position)
	if not ok: failures+=1
func place(pos: Vector3):
	Input.action_release("crouch")
	p.position=pos
	p.rotation=Vector3.ZERO
	p.velocity=Vector3.ZERO
	await frames(4)
func walk(action: String,n: int):
	Input.action_press(action)
	await frames(n)
	Input.action_release(action)
	await frames(3)
func run():
	Engine.max_fps=60
	h=load("res://scenes/horror/house_layout.tscn").instantiate()
	root.add_child(h)
	current_scene=h
	h.set_process(false)
	h.get_node("Visitation").set_physics_process(false)
	p=h.get_node("Player")
	for wall in get_nodes_in_group("weak_walls"):
		for i in range(wall.required_hits): wall.strike(Vector3.LEFT)
	await frames(4)
	await place(Vector3(.70,3.45,4.9))
	await walk("move_left",30)
	check(p.position.x>.15,"Service passage blocks a standing player")
	Input.action_press("crouch")
	await walk("move_left",70)
	check(p.position.x<-.3 and p.position.x>-1.0,"Broken master-bedroom wall opens into the hidden passage")
	await walk("move_back",390)
	check(p.position.z>14.3,"Hidden passage traverses the full west side of the house")
	p.position.z=14.55
	await walk("move_right",90)
	check(p.position.x>.6,"Passage exits into a different room, the upper store")
	await walk("move_left",90)
	check(p.position.x<-.3,"Upper-store shortcut works in reverse")
	await place(Vector3(15.5,3.45,10.3))
	await walk("move_back",50)
	check(p.position.z<11.9,"Bedroom wall still requires crouching after breaking")
	Input.action_press("crouch")
	await walk("move_back",65)
	check(p.position.z>12.6,"Behind-wardrobe shortcut reaches the south bedroom")
	await walk("move_forward",65)
	check(p.position.z<12,"Wardrobe shortcut works in reverse")
	await place(Vector3(11.3,.05,4.8))
	await walk("move_forward",36)
	check(p.position.z<3.4,"Ladder closet has a traversable doorway")
	print("SECRET_ROUTES_TEST failures=",failures)
	h.free()
	await process_frame
	quit(1 if failures else 0)
