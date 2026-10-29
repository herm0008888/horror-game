extends SceneTree
var failures:=0
func check(ok: bool,label: String):
 print("PASS " if ok else "FAIL ",label)
 if not ok:failures+=1
func _initialize():call_deferred("run")
func run():
 Engine.max_fps=0
 var h=load("res://scenes/horror/house_layout.tscn").instantiate()
 root.add_child(h)
 var player=h.get_node("Player");player.set_physics_process(false)
 var enemy=h.get_node("Visitation");enemy.set_physics_process(false)
 var tools=player.get_node("ToolController")
 var service=h.get_node("PropInteraction")
 for frame in range(5):await physics_frame
 check(service.roots.size()>150,"Furniture and decor registered")
 var sofa=h.get_node("GroundFloorDressing/LivingRoom/Sofa02")
 var small: Node3D
 for prop in service.roots:
  if service.should_highlight(prop) and prop.has_node("PickupTarget"):
   small=prop;break
 print("SMALL_PROP ",small.get_path() if small else "missing")
 check(not service.should_highlight(sofa),"Sofa has no highlight")
 check(service.should_highlight(small),"Small prop can highlight")
 check(small.has_node("PickupTarget"),"Decor without collision gets an interaction target")
 var sofa_transform: Transform3D=sofa.global_transform
 var sofa_body=service.make_body(sofa)
 check(sofa_body is RigidBody3D,"Sofa converts to physics body")
 check(sofa.global_transform.is_equal_approx(sofa_transform),"Converting preserves exact visible sofa placement")
 check(sofa.collision_layer==0 and sofa_body.get_child_count()>1,"Original static shell disabled, physical shapes retained")
 var box: AABB=service.world_bounds(sofa_body)
 player.position=box.get_center()+Vector3(0,0,2.1)-Vector3.UP*1.6
 player.camera.look_at(box.get_center())
 tools.grab(sofa_body)
 check(tools.grabbed==sofa_body and tools.grabbed_large,"Large sofa can be held")
 check(not sofa_body.freeze and sofa_body.gravity_scale==0,"Held furniture remains a colliding physics body")
 check(tools.grabbed_distance>1.5,"Large furniture held farther ahead")
 tools.drop_grabbed()
 check(not sofa_body.freeze and sofa_body.gravity_scale>0,"Dropped sofa restores gravity")
 var cabinet=h.get_node("GroundFloorDressing/LivingRoom/PaintedWoodenCabinet")
 var cabinet_body=service.make_body(cabinet)
 var doors=cabinet.find_children("*","AnimatableBody3D",true,false)
 check(cabinet_body is RigidBody3D and not doors.is_empty(),"Whole cabinet lifts while retaining hinges")
 var door=doors[0];door.set_open(true,true)
 check(door.opened,"Cabinet doors can still open after conversion")
 var bowl_body=service.make_body(small)
 bowl_body.global_position.y+=.4
 var before: float=bowl_body.global_position.y
 bowl_body.freeze=false
 for frame in range(30):await physics_frame
 check(bowl_body.global_position.y<before-.01,"Dropped small prop falls with physics")
 print("UNIVERSAL_PICKUP_TEST roots=",service.roots.size()," failures=",failures)
 h.free();quit(1 if failures else 0)
