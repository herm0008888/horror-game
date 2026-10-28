extends SceneTree
var failures:=0
func check(ok:bool,message:String):
 print("PASS " if ok else "FAIL ",message)
 if not ok:failures+=1
func _initialize():call_deferred("run")
func run():
 var figure=load("res://scenes/horror/figure_visual.tscn").instantiate()
 var visitor=load("res://scenes/horror/visitation.tscn").instantiate()
 var sk=figure.get_node("TheHollowVisitor_Rig/Skeleton3D")
 var a=sk.get_node("TheHollowVisitor_Mesh")
 var b=visitor.get_node("Figure/TheHollowVisitor_Rig/Skeleton3D/TheHollowVisitor_Mesh")
 check(a.mesh==b.mesh,"Both scenes use the same sculpt and expressions")
 check(a.get_active_material(3)==b.get_active_material(3),"White eye material is identical in both scenes")
 check(not visitor.find_child("RecessedSockets",true,false),"No black socket overlays cover the eyes")
 var container=Node3D.new();root.add_child(container);container.add_child(figure)
 var motion=load("res://scripts/horror/haunted_motion.gd").new();container.add_child(motion)
 var bones={};var rest={}
 for i in sk.get_bone_count():bones[sk.get_bone_name(i)]=i;rest[sk.get_bone_name(i)]=sk.get_bone_pose_rotation(i)
 for i in range(120):motion.animate(1.0/60,true,false,figure,sk,bones,rest)
 var neutral=a.get_blend_shape_value(a.find_blend_shape_by_name("Threat"))
 for i in range(120):motion.animate(1.0/60,true,true,figure,sk,bones,rest)
 check(a.get_blend_shape_value(a.find_blend_shape_by_name("Threat"))>neutral+.5,"Chase visibly changes facial expression")
 check(absf(sk.get_bone_pose_scale(bones.EyeLeft).x-1)<.001,"Eyes retain original size")
 var im=ImporterMesh.from_mesh(a.mesh)
 check(im.get_surface_lod_count(0)>0 and im.get_surface_lod_count(7)>0,"Hair and gown retain distance LODs")
 check(im.get_surface_lod_indices(0,im.get_surface_lod_count(0)-1).size()<20000,"Detailed hair has an efficient distant LOD")
 visitor.free();container.free()
 print("VISITOR_CONSISTENCY_TEST failures=",failures)
 quit(failures)

