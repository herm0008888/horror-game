extends Node
## Objects stay authored in their original scenes. Physics bodies are created on
## first pickup, so untouched dressing does not become hundreds of active bodies.
@export var small_item_size: float=0.65
var roots: Array[Node3D]=[]
var physics_bodies: Dictionary={}
func _ready() -> void:
 add_to_group("prop_interaction")
 for node in get_parent().find_children("*","Node3D",true,false):
  if eligible(node) and resolve(node)==node:register_prop(node)
func eligible(node: Node) -> bool:
 if not node is Node3D:return false
 if node.has_meta("asset_id") or node is RigidBody3D:return true
 var path:=node.scene_file_path
 return path.begins_with("res://scenes/horror/furniture/") or path.begins_with("res://addons/prop_library/props/") or path.begins_with("res://scenes/horror/decor/") or path.begins_with("res://assets/house_library/") or (node is RigidBody3D and node.get_script()!=null and node.get_script().resource_path.ends_with("loose_prop.gd"))
func resolve(node: Node) -> Node3D:
 var cursor:=node
 var fallback: Node3D
 while cursor and cursor!=get_parent():
  if cursor is Node3D:
   if cursor.is_in_group("carryable_physics"):return cursor
   if cursor.has_meta("asset_id"):return cursor
   if eligible(cursor):fallback=cursor
  cursor=cursor.get_parent()
 return fallback
func world_bounds(node: Node3D) -> AABB:
 var box:=AABB()
 var meshes:=node.find_children("*","MeshInstance3D",true,false)
 if node is MeshInstance3D:meshes.append(node)
 for mesh in meshes:
  if not mesh.mesh or not mesh.visible:continue
  var part: AABB=mesh.global_transform*mesh.get_aabb()
  box=part if box.size.length_squared()<.000001 else box.merge(part)
 return box
func should_highlight(node: Node3D) -> bool:
 if not is_instance_valid(node):return false
 var size:=world_bounds(node).size
 return size.length_squared()>0.000001 and maxf(size.x,maxf(size.y,size.z))<=small_item_size
func register_prop(node: Node3D) -> void:
 if roots.has(node):return
 var box:=world_bounds(node)
 if box.size.length_squared()<.000001:return
 roots.append(node)
 # Existing bodies, hinges and drawers already provide precise interaction hits.
 if node is PhysicsBody3D or not node.find_children("*","CollisionShape3D",true,false).is_empty():return
 var area:=Area3D.new();area.name="PickupTarget";area.collision_layer=32;area.collision_mask=0;area.monitoring=false;area.monitorable=false
 node.add_child(area)
 area.global_transform=Transform3D(Basis.IDENTITY,box.get_center())
 var collision:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=box.size.max(Vector3.ONE*.025);collision.shape=shape;area.add_child(collision)
func body_colliders(body: RigidBody3D) -> Array[PhysicsBody3D]:
 var result: Array[PhysicsBody3D]=[body]
 for child in body.find_children("*","PhysicsBody3D",true,false):result.append(child)
 return result
func shape_points(shape: Shape3D) -> PackedVector3Array:
 if shape is BoxShape3D:
  var points:=PackedVector3Array()
  for x in [-1,1]:
   for y in [-1,1]:
    for z in [-1,1]:points.append(shape.size*Vector3(x,y,z)*.5)
  return points
 if shape is ConvexPolygonShape3D:return shape.points
 if shape is ConcavePolygonShape3D:return shape.get_faces()
 return PackedVector3Array()
func add_hull(body: RigidBody3D, points: PackedVector3Array, transform: Transform3D) -> void:
 if points.size()<4:return
 var transformed:=PackedVector3Array()
 # Bound hull construction cost for detailed imported meshes, retain extrema.
 var stride:=maxi(1,points.size()/768)
 for i in range(0,points.size(),stride):transformed.append(transform*points[i])
 for axis in range(3):
  var low:=points[0];var high:=points[0]
  for point in points:
   if point[axis]<low[axis]:low=point
   if point[axis]>high[axis]:high=point
  transformed.append(transform*low);transformed.append(transform*high)
 var shape:=ConvexPolygonShape3D.new();shape.points=transformed;shape.margin=.003
 var collision:=CollisionShape3D.new();collision.name="CarryCollision";collision.shape=shape;body.add_child(collision)
func make_body(node: Node3D) -> RigidBody3D:
 if node is RigidBody3D:return node
 if physics_bodies.has(node) and is_instance_valid(physics_bodies[node]):return physics_bodies[node]
 var box:=world_bounds(node)
 if box.size.length_squared()<.000001:return null
 var body:=RigidBody3D.new();body.name=str(node.name)+"Physics"
 body.freeze=true;body.collision_layer=1;body.collision_mask=5
 body.mass=clampf(box.size.x*box.size.y*box.size.z*28.0,.15,80.0)
 body.linear_damp=.6;body.angular_damp=1.8;body.continuous_cd=true
 body.add_to_group("carryable_physics")
 get_parent().add_child(body);body.global_position=box.get_center()
 # Convert the static shell only. Hinged storage panels retain their scripts.
 var copied:=0
 for collision in node.find_children("*","CollisionShape3D",true,false):
  if collision.disabled or not collision.get_parent() is StaticBody3D:continue
  var points:=shape_points(collision.shape)
  if points.is_empty():continue
  add_hull(body,points,body.global_transform.affine_inverse()*collision.global_transform);copied+=1
 if copied==0:
  var meshes:=node.find_children("*","MeshInstance3D",true,false)
  if node is MeshInstance3D:meshes.append(node)
  for mesh in meshes:
   if mesh.mesh:add_hull(body,mesh.mesh.get_faces(),body.global_transform.affine_inverse()*mesh.global_transform)
 if body.get_child_count()==0:
  body.queue_free();return null
 var static_bodies:=node.find_children("*","StaticBody3D",true,false)
 if node is StaticBody3D:static_bodies.append(node)
 for old in static_bodies:old.collision_layer=0;old.collision_mask=0
 node.reparent(body,true)
 for area in node.find_children("PickupTarget","Area3D",true,false):area.collision_layer=0
 for child in body_colliders(body):
  if child!=body:body.add_collision_exception_with(child)
 physics_bodies[node]=body
 return body
