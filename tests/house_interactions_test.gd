extends SceneTree
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,title: String) -> void:
	print("PASS " if ok else "FAIL ",title)
	if not ok: failures+=1
func run() -> void:
	var h: Node3D=load("res://scenes/horror/house_layout.tscn").instantiate()
	root.add_child(h)
	h.set_process(false)
	var p: CharacterBody3D=h.get_node("Player")
	p.set_physics_process(false)
	h.get_node("Visitation").set_physics_process(false)
	for i in range(8): await physics_frame
	var parts:=get_nodes_in_group("openable_storage")
	check(parts.size()>=44,"Furniture parts registered: "+str(parts.size()))
	for part in parts:
		var closed: Transform3D=part.transform
		part.set_open(true,true)
		check(not part.transform.is_equal_approx(closed),"Open "+str(part.name))
		part.set_open(false,true)
		if not part.transform.is_equal_approx(closed): failures+=1
	check(h.has_node("InteractionCrosshair/Screen/Dot"),"Crosshair present")
	p.position=Vector3(6,-3.39,14)
	p.camera.rotation=Vector3.ZERO
	check(p.acquire_flashlight(),"Acquire flashlight")
	p.drop_held_item()
	await physics_frame
	check(not p.get_node("Camera/FlashlightRig").equipped,"Q releases held flashlight")
	var drops: Array=[]
	for n in h.get_children():
		if n is RigidBody3D and not n.freeze: drops.append(n)
	check(drops.size()==1,"One physical dropped flashlight")
	if drops.size()==1:
		var item: RigidBody3D=drops[0]
		p.position=item.global_position-Vector3(0,1,0)
		item.interact()
		await process_frame
		check(p.get_node("Camera/FlashlightRig").equipped,"Dropped flashlight can be picked up")
	var map: RID=h.get_world_3d().navigation_map
	var pairs: Array=[
		["Ground rooms",Vector3(3,0,3.9),Vector3(14,0,13)],
		["Basement stairs",Vector3(2.8,-3.4,11),Vector3(5.5,0,11)],
		["Upper stairs",Vector3(14,0,2),Vector3(5.5,3.4,11)]
	]
	for pair in pairs:
		var start:=NavigationServer3D.map_get_closest_point(map,pair[1])
		var end:=NavigationServer3D.map_get_closest_point(map,pair[2])
		var path:=NavigationServer3D.map_get_path(map,start,end,true)
		check(path.size()>1 and path[-1].distance_to(end)<0.3,str(pair[0])+" connected")
	print("HOUSE_INTERACTIONS_TEST failures=",failures)
	h.free()
	await process_frame
	quit(1 if failures else 0)
