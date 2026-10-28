extends SceneTree
var failures:=0
func _initialize(): call_deferred("run")
func frames(n: int):
	for i in range(n): await physics_frame
func check(ok: bool,title: String):
	print("PASS " if ok else "FAIL ",title)
	if not ok: failures+=1
func doors(node: Node,opened: bool):
	for part in node.find_children("*","AnimatableBody3D",true,false):
		if part.has_method("set_open"): part.set_open(opened,true)
func run():
	Engine.max_fps=60
	var h=load("res://scenes/horror/house_layout.tscn").instantiate()
	root.add_child(h)
	h.set_process(false)
	var p=h.get_node("Player")
	var e=h.get_node("Visitation")
	e.set_physics_process(false)
	var cabinet=h.get_node("BedroomWardrobe")
	doors(cabinet,true)
	p.position=Vector3(14,3.46,9.8)
	p.rotation=Vector3.ZERO
	p.velocity=Vector3.ZERO
	await frames(4)
	Input.action_press("move_back")
	await frames(26)
	Input.action_release("move_back")
	await frames(4)
	check(p.position.z>10.85 and p.position.z<11.4,"Player can walk into the deep wardrobe")
	doors(cabinet,false)
	e.position=Vector3(14,3.4,9.4)
	e.figure.rotation.y=PI
	await frames(4)
	check(not e.can_see_player(),"Closed wardrobe doors conceal the player from the creature")
	doors(cabinet,true)
	await frames(4)
	check(e.can_see_player(),"Opening the wardrobe exposes the player again")
	p.set_physics_process(false)
	p.position=Vector3(6.9,3.46,.65)
	e.position=Vector3(6.9,3.4,2.5)
	e.figure.rotation.y=0
	var master=h.get_node("UpperDressing/MasterBedroom/MasterHidingWardrobe")
	doors(master,false)
	await frames(4)
	check(not e.can_see_player(),"Master-bedroom hiding wardrobe also blocks sight")
	print("HIDING_WARDROBES_TEST failures=",failures)
	h.free()
	await process_frame
	quit(1 if failures else 0)
