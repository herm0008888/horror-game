extends SceneTree
var failed:=0
func _initialize(): call_deferred("run")
func run():
	var house=load("res://scenes/horror/house_layout.tscn").instantiate()
	root.add_child(house)
	house.set_process(false)
	house.get_node("Player").set_physics_process(false)
	await physics_frame
	await physics_frame
	var shape:=CapsuleShape3D.new()
	shape.radius=.27
	shape.height=1.7
	var query:=PhysicsShapeQueryParameters3D.new()
	query.shape=shape
	query.collision_mask=1
	query.exclude=[house.get_node("Player").get_rid()]
	var routes=[
		["study doorway",Vector3(2.6,0,3.9),Vector3(5.7,0,3.9)],
		["kitchen west aisle",Vector3(5.65,0,3.9),Vector3(5.65,0,8.7)],
		["kitchen east aisle",Vector3(11.3,0,3.9),Vector3(11.3,0,8.7)],
		["back stair approach",Vector3(11,0,5.1),Vector3(13,0,5.1)],
		["ladder approach",Vector3(11.6,0,4.6),Vector3(11.6,0,2.6)],
		["utility west door",Vector3(11.2,0,8),Vector3(14,0,8)],
		["utility south loop",Vector3(14,0,8),Vector3(14,0,11.1)],
		["living east door",Vector3(14.4,0,11),Vector3(14.4,0,14.6)],
		["living main door",Vector3(10.5,0,11.2),Vector3(10.5,0,13.3)],
		["living cross route",Vector3(10.5,0,13),Vector3(14.4,0,13)],
		["main stair approach",Vector3(3,0,11),Vector3(6,0,11)],
		["front store doorway",Vector3(2,0,11.5),Vector3(2,0,14.3)],
		["plank pickup access",Vector3(10.7,0,9),Vector3(9,0,9)],
		["entrance approach",Vector3(6,0,11),Vector3(6,0,12.5)]
	]
	for route in routes:
		var blocked:=false
		for i in range(51):
			var pos: Vector3=route[1].lerp(route[2],i/50.0)
			query.transform=Transform3D(Basis.IDENTITY,pos+Vector3(0,.91,0))
			var hits=house.get_world_3d().direct_space_state.intersect_shape(query,8)
			if not hits.is_empty():
				print("FAIL ",route[0]," at ",pos," collider=",hits[0].collider.get_path())
				failed+=1
				blocked=true
				break
		if not blocked: print("PASS ",route[0])
	print("GROUND_CLEARANCE_TEST ","PASS" if failed==0 else "FAIL"," failures=",failed)
	house.free()
	quit(0 if failed==0 else 1)
