extends SceneTree
var failures:=0
func _initialize(): call_deferred("run")
func check(ok: bool,title: String):
	print("PASS " if ok else "FAIL ",title)
	if not ok: failures+=1
func run():
	var h=load("res://scenes/horror/house_layout.tscn").instantiate()
	root.add_child(h)
	current_scene=h
	h.set_process(false)
	var p=h.get_node("Player")
	p.set_physics_process(false)
	h.get_node("Visitation").set_physics_process(false)
	for i in range(4): await physics_frame
	var hammer=h.find_child("SledgehammerPickup",true,false)
	check(hammer!=null,"Hammer is available outside the prison bars")
	p.position=Vector3(7.15,-3.35,12.65)
	hammer.interact()
	check(p.get_node("ToolController").hammer_equipped,"Hammer can be collected from inside the cell")
	var wall=h.find_child("WeakCellRepair",true,false)
	check(not wall.broken,"Cell escape starts as a solid cracked wall")
	p.position=Vector3(5,-3.35,15.2)
	p.camera.look_at(wall.global_position)
	p.get_node("ToolController").strike()
	check(wall.hits==1 and not wall.broken,"First hammer strike damages the repair")
	p.get_node("ToolController").strike()
	for i in range(3): await physics_frame
	check(wall.broken and wall.get_node("Collision").disabled,"Second strike opens a real crawl gap")
	check(h.get_tree().get_nodes_in_group("weak_walls").size()>=4,"Upper floor has additional breakable shortcuts")
	var upper=h.get_node("UpperDressing")
	check(upper.get_child_count()>=8,"Every upstairs area is authored separately")
	var bodies=upper.find_children("*","RigidBody3D",true,false)
	check(bodies.size()>=10,"Loose objects use real rigid bodies")
	var loose=bodies[0]
	var y=loose.global_position.y
	loose.global_position.y+=.5
	loose.sleeping=false
	for i in range(45): await physics_frame
	check(loose.global_position.y<y+.4,"Released objects fall under gravity")
	check(p.get_node("ToolController").drop_held(),"Hammer can be dropped")
	for i in range(3): await physics_frame
	check(not p.get_node("ToolController").hammer_equipped,"Drop clears the held hammer")
	print("UPGRADE_GAMEPLAY_TEST failures=",failures)
	h.free()
	await process_frame
	quit(1 if failures else 0)
