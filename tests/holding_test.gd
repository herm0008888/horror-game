extends SceneTree
var failures:=0
func _initialize(): call_deferred("run")
func check(ok: bool,message: String):
	print("PASS " if ok else "FAIL ",message)
	if not ok: failures+=1
func slots(p,h,t) -> int:
	return int(t.hammer_equipped)+int(is_instance_valid(t.grabbed))+int(p.get_node("Camera/FlashlightRig").equipped)+int(h.carrying_plank)
func run():
	var h=load("res://scenes/horror/house_layout.tscn").instantiate()
	root.add_child(h);current_scene=h;h.set_process(false)
	var p=h.get_node("Player")
	p.set_physics_process(false)
	h.get_node("Visitation").set_physics_process(false)
	var t=p.get_node("ToolController")
	t.set_physics_process(false)
	for i in range(3): await physics_frame
	p.release_hand_items()
	p.acquire_flashlight(false)
	var hammer=h.find_child("SledgehammerPickup",true,false)
	p.global_position=Vector3(7.15,-3.35,12.65)
	hammer.interact()
	check(slots(p,h,t)==1 and t.hammer_equipped,"Hammer replaces flashlight")
	check(not p.get_node("Camera/FlashlightRig").equipped,"Replaced flashlight is released")
	for m in t.held.find_children("*","MeshInstance3D",true,false):
		check(not m.material_override.uv1_world_triplanar and m.material_override.next_pass==null,"Hammer texture uses local coordinates without world decay pass")
	check(t.held.position==t.REST_POSITION,"Hammer rests at the hand pivot")
	var wall=h.find_child("WeakCellRepair",true,false)
	p.global_position=Vector3(5,-3.35,15.2);p.camera.look_at(wall.global_position)
	t.begin_swing();t._physics_process(.08)
	check(wall.hits==0,"Wind-up does not hit early")
	t._physics_process(.02)
	check(wall.hits==1,"Fast forward strike lands within 100 milliseconds")
	t._physics_process(.2)
	check(wall.hits==1 and t.swing_left==0 and t.held.position.is_equal_approx(t.REST_POSITION),"One hit per swing and full recovery within 280 milliseconds")
	var loose=RigidBody3D.new();h.add_child(loose);loose.global_position=p.camera.global_position+Vector3.FORWARD*.5
	t.grab(loose)
	check(slots(p,h,t)==1 and t.grabbed==loose and not t.hammer_equipped,"Loose object replaces and drops hammer")
	p.acquire_flashlight(true)
	check(slots(p,h,t)==1 and not loose.freeze,"Flashlight replaces and releases loose object")
	h.intro_done=true;p.position=h.plank.global_position+Vector3.UP*.1
	var action=InputEventAction.new();action.action="interact";action.pressed=true
	h._unhandled_input(action)
	check(slots(p,h,t)==1 and h.carrying_plank,"Plank replaces flashlight")
	var dropped=load("res://scenes/horror/sledge_pickup.tscn").instantiate();h.add_child(dropped)
	dropped.position=p.camera.global_position;dropped.interact()
	check(slots(p,h,t)==1 and t.hammer_equipped and not h.carrying_plank and h.plank.visible,"Hammer replaces plank and restores it to the world")
	t.begin_swing();t.drop_held()
	check(slots(p,h,t)==0 and t.swing_left==0,"Dropping mid-swing clears hand and animation")
	p.global_position=Vector3(6,-3.35,14)
	p.camera.rotation=Vector3.ZERO
	var first=RigidBody3D.new()
	first.set_script(load("res://scripts/horror/loose_prop.gd"))
	var second=RigidBody3D.new()
	second.set_script(load("res://scripts/horror/loose_prop.gd"))
	for body in [first,second]:
		var shape=CollisionShape3D.new();shape.shape=SphereShape3D.new();shape.shape.radius=.12
		body.add_child(shape);h.add_child(body);body.freeze=true
	first.global_position=p.camera.global_position-p.camera.global_basis.z*.6
	second.global_position=p.camera.global_position-p.camera.global_basis.z*1.4
	t.grab(first)
	for i in range(3): await physics_frame
	p._unhandled_input(action)
	check(t.grabbed==second and not first.freeze and slots(p,h,t)==1,"Interaction ray can select the next object while already holding one")
	print("SINGLE_HAND_TEST failures=",failures)
	h.free();await process_frame;quit(1 if failures else 0)
