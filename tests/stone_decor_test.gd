extends SceneTree
func _initialize() -> void: call_deferred("run")
func collect(node: Node,t: Transform3D,boxes: Array[AABB]) -> void:
	if node is Node3D: t=t*node.transform
	if node is MeshInstance3D: boxes.append(t*node.get_aabb())
	for child in node.get_children(): collect(child,t,boxes)
func run() -> void:
	var house: Node3D=load("res://scenes/horror/house_layout.tscn").instantiate()
	root.add_child(house)
	house.set_process(false)
	house.get_node("Player").set_physics_process(false)
	await physics_frame
	await physics_frame
	var failures:=0
	var checked:=0
	for item in house.get_node("StoneAndWorkshopDecor").get_children():
		var boxes: Array[AABB]=[]
		collect(item,Transform3D.IDENTITY,boxes)
		var box:=boxes[0]
		for b in boxes: box=box.merge(b)
		var base:=Vector3(box.get_center().x,box.position.y,box.get_center().z)
		var query:=PhysicsRayQueryParameters3D.create(base+Vector3.UP*0.025,base-Vector3.UP*0.025,1)
		query.exclude=[house.get_node("Player").get_rid()]
		var hit:=house.get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty() or absf(hit.position.y-base.y)>0.005:
			print("FAIL support ",item.name," ",base)
			failures+=1
		if str(item.name).begins_with("LooseStone") and (box.size.x>0.29 or box.size.z>0.29 or box.size.y>0.30):
			print("FAIL stone scale ",item.name," ",box.size)
			failures+=1
		checked+=1
	print("STONE_DECOR_TEST checked=",checked," failures=",failures)
	house.free()
	await process_frame
	quit(1 if failures else 0)
