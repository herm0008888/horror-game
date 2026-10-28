extends SceneTree
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,title: String) -> void:
	print("PASS " if ok else "FAIL ",title)
	if not ok: failures+=1
func center(part: Node3D) -> Vector3:
	var first:=true
	var box:=AABB()
	for m in part.find_children("*","MeshInstance3D",true,false):
		var b: AABB=part.transform*m.transform*m.get_aabb()
		box=b if first else box.merge(b)
		first=false
	return box.get_center()
func run() -> void:
	var h: Node3D=load("res://scenes/horror/house_layout.tscn").instantiate()
	root.add_child(h)
	h.set_process(false)
	var p: CharacterBody3D=h.get_node("Player")
	var e: CharacterBody3D=h.get_node("Visitation")
	p.set_physics_process(false)
	e.set_physics_process(false)
	e.position=Vector3(6.095,-3.39,10.5)
	e.figure.rotation.y=PI
	p.position=Vector3(6.095,-3.39,14)
	for i in range(5): await physics_frame
	var ray:=PhysicsRayQueryParameters3D.create(e.sight_origin(),p.camera.global_position,8)
	ray.collide_with_areas=true
	ray.collide_with_bodies=false
	check(not h.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(),"Grille covers sight between bars")
	check(not e.can_see_player(),"Cannot see player through grille")
	p.position=Vector3(6.095,-3.39,9)
	check(not e.can_see_player(),"Cannot see player behind her even nearby")
	p.position=Vector3(6.095,-3.39,11.2)
	e.sees_player=true
	check(not e.should_track_player(Vector3(0,0,-1)),"No stare while walking away")
	check(e.should_track_player(Vector3(0,0,1)),"Can look toward visible player ahead")
	e.sees_player=false
	check(not e.should_track_player(Vector3.ZERO),"No stare after losing sight")
	var checked:=0
	for part in get_nodes_in_group("openable_storage"):
		if part.open_offset.length()>0.01: continue
		var before:=center(part)
		var closed: Transform3D=part.transform
		part.set_open(true,true)
		var after:=center(part)
		var id: String=str(part.get_parent().get_meta("asset_id",""))
		if str(part.name)=="Lid": check(after.y>before.y+0.02,"Lid opens upward "+str(part.get_parent().name))
		else: check(after.z>before.z+0.02,"Door opens outward "+id+" "+str(part.name))
		check(part.position.distance_to(closed.origin)<0.0001,"Hinge remains attached")
		part.set_open(false,true)
		check(part.transform.is_equal_approx(closed),"Returns to closed hinge pose")
		checked+=1
	print("SIGHT_AND_HINGES_TEST parts=",checked," failures=",failures)
	h.free()
	await process_frame
	quit(1 if failures else 0)
