extends SceneTree
var failures:=0
func check(ok: bool,label: String):
 print("PASS " if ok else "FAIL ",label)
 if not ok:failures+=1
func _initialize():call_deferred("run")
func wait_revision(nav, wanted: int):
 for frame in range(1000):
  await physics_frame
  if nav.revision>=wanted:return true
 return false
func run():
 Engine.max_fps=0
 var h=load("res://scenes/horror/house_layout.tscn").instantiate();root.add_child(h)
 var p=h.get_node("Player");p.set_physics_process(false)
 var e=h.get_node("Visitation");e.set_physics_process(false)
 var nav=h.get_node("HouseNavigation");var service=h.get_node("PropInteraction")
 check(await wait_revision(nav,1),"Navigation rebuilds from live geometry at startup")
 e.position=Vector3(30,0,30);p.position=Vector3(30,0,28.65);e.figure.rotation=Vector3.ZERO;e.hunt=5;e.sees_player=true
 for frame in range(3):await physics_frame
 check(e.can_catch_player(),"Catch reaches player without overlapping bodies")
 var wall:=StaticBody3D.new();var c:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=Vector3(3,3,.12);c.shape=shape;wall.add_child(c);h.add_child(wall);wall.position=Vector3(30,1.2,29.4)
 for frame in range(3):await physics_frame
 check(not e.can_catch_player(),"Catch cannot go through a wall")
 wall.free();p.position=Vector3(100,0,100)
 var sofa=h.get_node("GroundFloorDressing/LivingRoom/Sofa02")
 var body: RigidBody3D=service.make_body(sofa);body.freeze=true;body.global_position=Vector3(9.5,.46,12.8)
 var old_revision: int=nav.revision;nav.request_update()
 check(await wait_revision(nav,old_revision+1),"Moved rigid furniture updates navigation")
 for frame in range(3):await physics_frame
 e.position=Vector3(5.5,0,11);e.velocity=Vector3.ZERO;e.recovery_left=0;e.stuck_time=0;e.previous_position=e.position;e.caught=false;e.last_seen=Vector3(14,0,13);e.hunt=999;e.repath=0;e.chase_speed=4;e.set_physics_process(true)
 var reached:=false
 for frame in range(1500):
  await physics_frame
  if e.position.distance_to(Vector3(14,0,13))<1:
   reached=true;break
 check(reached,"Enemy routes around newly positioned sofa")
 e.set_physics_process(false)
 var mesh=e.figure.find_child("TheHollowVisitor_Mesh",true,false)
 var uv_ok:=true
 for surface in [6,7,8,9]:
  var arrays: Array=mesh.mesh.surface_get_arrays(surface)
  uv_ok=uv_ok and arrays[Mesh.ARRAY_TEX_UV].size()==arrays[Mesh.ARRAY_VERTEX].size()
 check(uv_ok,"Animated body surfaces have fixed UV coordinates")
 var pot=h.get_node("UpperDressing/UpperLanding/CeramicPotLoose")
 pot.freeze=true;pot.global_position=Vector3(6,.02,11)
 var pot_box: AABB=service.world_bounds(pot)
 e.position=Vector3(6,pot_box.end.y+.025,11);e.velocity=Vector3.ZERO;e.chase_speed=0;e.repath=0;e.last_seen=Vector3(6,0,8.5);e.hunt=999;e.set_physics_process(true)
 for frame in range(30):await physics_frame
 var start: Vector3=e.position
 e.chase_speed=4
 for frame in range(300):
  await physics_frame
  if Vector2(e.position.x-start.x,e.position.z-start.z).length()>1 and e.position.y<.2:break
 check(e.get_collision_exceptions().has(pot),"Small pot cannot become the enemy's floor")
 check(Vector2(e.position.x-start.x,e.position.z-start.z).length()>1 and e.position.y<.2,"Enemy gets down from pot and continues chasing")
 e.set_physics_process(false)
 print("ADAPTIVE_PURSUIT_TEST revision=",nav.revision," failures=",failures)
 nav.set_process(false)
 while nav.busy:await process_frame
 h.free();quit(1 if failures else 0)
