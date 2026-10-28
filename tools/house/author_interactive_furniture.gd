extends SceneTree
var changes: Array=[]
var parts:=0
var furniture:=0
const TYPES=["painted_wooden_cabinet","painted_wooden_cabinet_02","painted_wooden_nightstand","metal_tool_chest","metal_toolbox","electric_stove","wooden_crate_01","wooden_crate_02","old_military_crate"]
func _initialize():call_deferred("run")
func own(n: Node,target: Node):
 for c in n.get_children():c.owner=target;own(c,target)
func collider(parent: Node3D,title: String,box: AABB):
 var n=CollisionShape3D.new();n.name=title
 var shape=BoxShape3D.new();shape.size=box.size.max(Vector3.ONE*.015);n.shape=shape;n.position=box.get_center();parent.add_child(n)
func frame(parent: Node3D,b: AABB,top_open: bool):
 var w=.035
 collider(parent,"LeftWall",AABB(b.position,Vector3(w,b.size.y,b.size.z)))
 collider(parent,"RightWall",AABB(Vector3(b.end.x-w,b.position.y,b.position.z),Vector3(w,b.size.y,b.size.z)))
 collider(parent,"BackWall",AABB(b.position,Vector3(b.size.x,b.size.y,w)))
 collider(parent,"Bottom",AABB(b.position,Vector3(b.size.x,w,b.size.z)))
 if top_open:collider(parent,"FrontWall",AABB(Vector3(b.position.x,b.position.y,b.end.z-w),Vector3(b.size.x,b.size.y,w)))
 else:collider(parent,"Top",AABB(Vector3(b.position.x,b.end.y-w,b.position.z),Vector3(b.size.x,w,b.size.z)))
func group_key(mesh: Node):
 var n=mesh
 while n and n.name!="Model":
  var title=str(n.name)
  if "drawer" in title:return title
  if "door" in title:return title
  if "lid" in title:return "Lid"
  n=n.get_parent()
 return ""
func create(original: Node3D,id: String,scene_path: String):
 var new=StaticBody3D.new();new.name=original.name
 root.add_child(new);new.global_transform=original.global_transform
 for key in original.get_meta_list():new.set_meta(key,original.get_meta(key))
 new.set_meta("interactive_storage",true)
 var originals={}
 for m in original.find_children("*","MeshInstance3D",true,false):originals[str(m.name)]=m
 var body_box=AABB();var first=true
 var groups={}
 for source in originals.values():
  var t=new.global_transform.affine_inverse()*source.global_transform
  var b=t*source.get_aabb()
  var key=group_key(source)
  if key.is_empty():body_box=b if first else body_box.merge(b);first=false
  else:
   if not groups.has(key):groups[key]=[]
   groups[key].append(source)
 if groups.is_empty():new.free();return
 frame(new,body_box,"crate" in id or "tool" in id)
 for source in originals.values():
  var key=group_key(source)
  if not key.is_empty():continue
  var clone=MeshInstance3D.new();clone.name=source.name;clone.mesh=source.mesh;clone.material_override=source.material_override
  for i in range(source.mesh.get_surface_count()):clone.set_surface_override_material(i,source.get_surface_override_material(i))
  new.add_child(clone);clone.global_transform=source.global_transform
 for key in groups:
  var moving=AnimatableBody3D.new();moving.name=str(key).to_pascal_case();moving.set_script(load("res://scripts/horror/storage_part.gd"));moving.collision_layer=1;moving.collision_mask=1
  new.add_child(moving)
  var first_mesh=groups[key][0]
  moving.position=new.to_local(first_mesh.global_position)
  var local_box=AABB();first=true
  for source in groups[key]:
   var clone=MeshInstance3D.new();clone.name=source.name;clone.mesh=source.mesh;clone.material_override=source.material_override
   for i in range(source.mesh.get_surface_count()):clone.set_surface_override_material(i,source.get_surface_override_material(i))
   moving.add_child(clone);clone.global_transform=source.global_transform
   var b=clone.transform*clone.get_aabb();local_box=b if first else local_box.merge(b);first=false
  collider(moving,"MovingCollision",local_box)
  if "drawer" in str(key):moving.open_offset=Vector3(0,0,minf(.48,local_box.size.z*.72))
  elif key=="Lid":
   if id=="metal_tool_chest":moving.rotation.x=PI/2
   elif id=="metal_toolbox":moving.rotation.x=deg_to_rad(56.5)
   moving.open_rotation_degrees=Vector3(-100,0,0)
  elif id=="electric_stove":moving.open_rotation_degrees=Vector3(85,0,0)
  else:moving.open_rotation_degrees=Vector3(0,-105 if moving.position.x<body_box.get_center().x else 105,0)
  var slots=Node3D.new();slots.name="ItemSlots";moving.add_child(slots)
  var marker=Marker3D.new();marker.name="Item01";marker.position=local_box.get_center();slots.add_child(marker)
  parts+=1
 var interior=Node3D.new();interior.name="InteriorItemSlots";new.add_child(interior)
 for i in range(3):
  var slot=Marker3D.new();slot.name="Item0"+str(i+1);slot.position=body_box.get_center()+Vector3(0,(i-1)*body_box.size.y*.22,0);interior.add_child(slot)
 new.transform=original.transform
 own(new,new)
 var path="res://scenes/horror/furniture/storage_%03d.tscn"%furniture
 var packed=PackedScene.new();packed.pack(new);ResourceSaver.save(packed,path)
 changes.append({"scene":scene_path,"node":str(original.name),"replacement":path})
 furniture+=1;new.free()
func run():
 DirAccess.make_dir_recursive_absolute("res://scenes/horror/furniture")
 var scenes=["basement_abandoned_cell","basement_rotten_storage","basement_dead_boiler_room","basement_ruined_workshop","basement_south_store","basement_escape_store","ground_living_room","ground_kitchen_dining","ground_study","ground_utility_room","ground_front_store"]
 for title in scenes:
  var path="res://scenes/horror/"+title+".tscn"
  var scene=load(path).instantiate();root.add_child(scene);scene.process_mode=Node.PROCESS_MODE_DISABLED
  for node in scene.get_children():
   if not node is Node3D or not node.has_node("Model"):continue
   var id=str(node.get_meta("asset_id",str(node.name).to_snake_case()))
   if id in TYPES:create(node,id,path)
  scene.free()
 var file=FileAccess.open("res://tools/house/interactive_furniture_manifest.json",FileAccess.WRITE);file.store_string(JSON.stringify(changes,"  "))
 print("FURNITURE_AUTHORED ",furniture," parts=",parts)
 quit()
