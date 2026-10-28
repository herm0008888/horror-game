extends SceneTree
func _initialize():call_deferred("run")
func shape(parent,title,pos,size,owner):
 var c=CollisionShape3D.new();c.name=title;var box=BoxShape3D.new();box.size=size;c.shape=box;c.position=pos;parent.add_child(c);c.owner=owner
func run():
 var dir=DirAccess.open("res://scenes/horror/furniture")
 for file in dir.get_files():
  if not file.ends_with(".tscn"):continue
  var path="res://scenes/horror/furniture/"+file;var scene=load(path).instantiate();var changed=false
  for part in scene.get_children():
   if not part is AnimatableBody3D or part.open_offset.length()<.01:continue
   var c=part.get_node("MovingCollision");var size=c.shape.size;var center=c.position;var a=center-size*.5;var z=center+size*.5;part.remove_child(c);c.free();var w=minf(.025,size.y*.25)
   shape(part,"TrayBottom",Vector3(center.x,a.y+w*.5,center.z),Vector3(size.x,w,size.z),scene)
   shape(part,"TrayLeft",Vector3(a.x+w*.5,center.y,center.z),Vector3(w,size.y,size.z),scene)
   shape(part,"TrayRight",Vector3(z.x-w*.5,center.y,center.z),Vector3(w,size.y,size.z),scene)
   shape(part,"TrayBack",Vector3(center.x,center.y,a.z+w*.5),Vector3(size.x,size.y,w),scene)
   shape(part,"TrayFront",Vector3(center.x,center.y,z.z-w*.5),Vector3(size.x,size.y,w),scene)
   changed=true
  if changed:
   var packed=PackedScene.new();packed.pack(scene);ResourceSaver.save(packed,path)
  scene.free()
 quit()
