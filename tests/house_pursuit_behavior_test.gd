extends SceneTree
var failures:=0
func check(ok: bool,label: String):
 print("PASS " if ok else "FAIL ",label)
 if not ok: failures+=1
func _initialize(): call_deferred("run")
func run():
 var h=load("res://scenes/horror/house_layout.tscn").instantiate()
 root.add_child(h)
 for i in range(8): await physics_frame
 var e=h.get_node("Visitation")
 var p=h.get_node("Player")
 e.set_physics_process(false)
 p.set_physics_process(false)
 e.sees_player=false
 e.hunt=0
 e.hear_noise(e.global_position+Vector3(0,3.4,0),35.0)
 check(e.hunt>=25 and e.state=="INVESTIGATE","wall crash heard across floors")
 var clue: Vector3=e.last_seen
 e.hear_noise(e.global_position+Vector3.RIGHT,4.8)
 check(e.last_seen==clue,"footsteps do not erase loud clue")
 e.ignoring_own_noise=true
 e.hear_noise(e.global_position+Vector3.RIGHT,12.0)
 e.ignoring_own_noise=false
 check(e.last_seen==clue,"own door noise does not replace pursuit")
 e.begin_search()
 check(e.state=="SEARCH" and e.search_left>=16,"persistent search after lost contact")
 var first: Vector3=e.choose_search_target()
 var second: Vector3=e.choose_search_target()
 check(first!=second,"search covers different locations")
 var mesh=e.figure.find_child("TheHollowVisitor_Mesh",true,false)
 var maximum:=0.0
 var minimum:=1.0
 for i in range(220):
  e.motion.animate(1.0/60,true,true,e.figure,e.pose_skeleton,e.pose_bones,e.pose_rest_rotations)
  var mouth: float=mesh.get_blend_shape_value(mesh.find_blend_shape_by_name("Scream"))
  maximum=maxf(maximum,mouth)
  minimum=minf(minimum,mouth)
 check(maximum>.6 and maximum-minimum>.4,"chase jaw opens and snaps shut")
 print("PURSUIT_BEHAVIOR_TEST failures=",failures)
 h.free()
 quit(1 if failures else 0)
