extends Node
## Keep editable tree nodes; batch their static render meshes only when playing.
func _ready():call_deferred("batch_forest")
func batch_forest():
 var exterior:=get_parent() as Node3D
 var forest:=exterior.get_node("DenseFirForest")
 var groups: Dictionary={}
 for mesh in forest.find_children("*","MeshInstance3D",true,false):
  if not mesh.mesh:continue
  var p: Vector3=exterior.to_local(mesh.global_position)
  var cell:=Vector2i(floori(p.x/12),floori(p.z/12))
  var key:=str(cell)+":"+str(mesh.mesh.get_instance_id())+":"+str(mesh.cast_shadow)
  if not groups.has(key):groups[key]={"cell":cell,"sources":[]}
  groups[key].sources.append(mesh)
 var batches:=Node3D.new();batches.name="RuntimeForestBatches";exterior.add_child(batches)
 for data in groups.values():
  var source: MeshInstance3D=data.sources[0]
  var chunk:=MultiMeshInstance3D.new();chunk.name="TreeChunk";batches.add_child(chunk)
  chunk.position=Vector3(data.cell.x*12+6,0,data.cell.y*12+6)
  var instances:=MultiMesh.new();instances.transform_format=MultiMesh.TRANSFORM_3D;instances.mesh=source.mesh;instances.instance_count=data.sources.size()
  for i in range(data.sources.size()):
   var original: MeshInstance3D=data.sources[i]
   instances.set_instance_transform(i,chunk.global_transform.affine_inverse()*original.global_transform)
   original.hide()
  chunk.multimesh=instances;chunk.material_override=source.material_override;chunk.cast_shadow=source.cast_shadow
  chunk.visibility_range_end=70;chunk.visibility_range_end_margin=6;chunk.lod_bias=.55
