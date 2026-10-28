extends SceneTree
var failures:=0
func _initialize():call_deferred("run")
func check(ok: bool,label: String):
	print("PASS " if ok else "FAIL ",label)
	if not ok:failures+=1
func run():
	var h=load("res://scenes/horror/house_layout.tscn").instantiate()
	root.add_child(h);current_scene=h;h.set_process(false)
	var p=h.get_node("Player");p.set_physics_process(false)
	h.get_node("Visitation").set_physics_process(false)
	var t=p.get_node("ToolController");t.set_physics_process(false)
	p.position=Vector3(7.15,-3.35,12.65)
	h.find_child("SledgehammerPickup",true,false).interact()
	var wall=h.find_child("WeakCellRepair",true,false)
	p.position=Vector3(5,-3.35,15.2);p.camera.look_at(wall.global_position)
	for i in range(3):await physics_frame
	var ids=[]
	for part in wall.pieces:ids.append(part.get_instance_id())
	check(ids.size()==12,"Intact wall is assembled from twelve pre-existing physical pieces")
	check(wall.wall_material.resource_path.ends_with("basement_wall.tres"),"Cell repair uses the surrounding cellar wall material")
	check(wall.get_node("Mesh").cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY,"Old repair slab and timber decoration are hidden")
	check(t.REST_POSITION.x>.5,"Hammer grip rests farther to the right")
	t.begin_swing();t._physics_process(0)
	check(not t.swing_hit.is_empty() and t.swing_hit.collider==wall,"Swing caches the real wall contact")
	t.animate_swing(t.HIT_TIME)
	var contact=t.held.global_transform*t.HEAD_CONTACT
	check(contact.distance_to(t.swing_hit.position)<.001,"Hammer's striking face reaches the ray contact within one millimetre")
	t._physics_process(.10)
	check(wall.hits==1 and not wall.broken,"Contact applies one damage step")
	t._physics_process(.2);t.begin_swing();t._physics_process(.1)
	for i in range(3):await physics_frame
	var same=true
	for i in range(wall.pieces.size()):same=same and wall.pieces[i].get_instance_id()==ids[i] and not wall.pieces[i].freeze
	check(wall.broken and same,"Breaking releases the identical wall pieces without spawning replacements")
	check(wall.get_node("Collision").disabled,"Broken opening has no blocking slab")
	var upper=h.find_child("WeakBedroomRepair",true,false)
	check(upper.wall_material.resource_path.ends_with("wall_wood.tres"),"Upstairs repair matches the surrounding wood")
	for piece in wall.pieces:
		check(not piece.get_node("Mesh").material_override.uv1_world_triplanar,"Released wall texture follows its piece")
	var high=wall.pieces[-1];var y=high.global_position.y
	for i in range(35):await physics_frame
	print("FALL ",y," -> ",high.global_position.y," velocity ",high.linear_velocity)
	check(high.global_position.y<y-.15,"Original wall pieces actually fall under gravity")
	print("HAMMER_WALL_TEST failures=",failures)
	h.free();await process_frame;quit(1 if failures else 0)
