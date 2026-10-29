extends SceneTree
var failures:=0
func _initialize():call_deferred("run")
func run():
 Engine.max_fps=0
 var h=load("res://scenes/horror/house_layout.tscn").instantiate();root.add_child(h)
 h.get_node("Player").set_physics_process(false);h.get_node("Visitation").set_physics_process(false)
 var service=h.get_node("PropInteraction")
 for frame in range(4):await physics_frame
 var count:=0
 for prop in service.roots.duplicate():
  if not is_instance_valid(prop):continue
  var before: Transform3D=prop.global_transform
  var body: RigidBody3D=service.make_body(prop)
  if body==null or not prop.global_transform.is_equal_approx(before):
   print("FAIL ",prop.name);failures+=1
  else:count+=1
 for frame in range(4):await physics_frame
 print("ALL_PROPS_PICKUP_TEST converted=",count," failures=",failures)
 h.free();quit(1 if failures else 0)
