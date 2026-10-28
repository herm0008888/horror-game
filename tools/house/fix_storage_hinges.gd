extends SceneTree
var corrected:=0
func _initialize():call_deferred("run")
func bounds(part):
 var first=true;var result=AABB()
 for m in part.find_children("*","MeshInstance3D",true,false):
  var box=part.transform*m.transform*m.get_aabb();result=box if first else result.merge(box);first=false
 return result
func rebase(part,frame):
 var old=part.transform
 for child in part.get_children():
  if child is Node3D:child.transform=frame.affine_inverse()*old*child.transform
 part.sync_to_physics=false;part.transform=frame
func run():
 for file in DirAccess.get_files_at("res://scenes/horror/furniture"):
  if not file.ends_with(".tscn"):continue
  var path="res://scenes/horror/furniture/"+file;var s=load(path).instantiate();var id=str(s.get_meta("asset_id",""))
  for p in s.get_children():
   if not p is AnimatableBody3D:continue
   if p.get_meta("hinge_fixed",false):continue
   p.sync_to_physics=false
   var b=bounds(p);var pivot=b.get_center();var rotation=Vector3.ZERO
   if p.open_offset.length()>.001:
    # Drawers translate without any angular motion.
    p.open_rotation_degrees=Vector3.ZERO;p.set_meta("hinge_fixed",true);continue
   if str(p.name)=="Lid":
    if id in ["metal_tool_chest","metal_toolbox"]:
     var axis_point=Vector3(b.get_center().x,b.position.y,b.position.z)
     var angle=PI/2 if id=="metal_tool_chest" else deg_to_rad(56.5)
     var turn=Basis(Vector3.RIGHT,angle)
     var delta=Transform3D(turn,axis_point-turn*axis_point)
     for child in p.get_children():
      if child is Node3D:child.transform=p.transform.affine_inverse()*delta*p.transform*child.transform
     b=bounds(p)
    pivot=b.get_center()
    if b.size.z>b.size.x*1.35:
     pivot.x=b.position.x;rotation=Vector3(0,0,100)
    else:
     pivot.z=b.position.z;rotation=Vector3(-100,0,0)
   elif id=="electric_stove":
    pivot.y=b.position.y;rotation=Vector3(90,0,0)
   else:
    var left=b.get_center().x<-.05
    if str(p.name)=="LeftDoor":left=true
    elif str(p.name)=="RightDoor":left=false
    pivot.x=b.position.x if left else b.end.x
    pivot.z=b.position.z
    rotation=Vector3(0,-100 if left else 100,0)
   rebase(p,Transform3D(Basis.IDENTITY,pivot))
   p.open_rotation_degrees=rotation
   p.set_meta("hinge_fixed",true)
   corrected+=1
  var packed=PackedScene.new();packed.pack(s);ResourceSaver.save(packed,path);s.free()
 print("CORRECTED_HINGES ",corrected)
 quit()
