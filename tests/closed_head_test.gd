extends SceneTree
func _initialize():
 var mesh=load("res://assets/horror/visitor_complete.res")
 var failures=0
 for mode in [-1,0,1]:
  var ids={};var edges={}
  for s in [1,2,8,10,11]:
   var arr=mesh.surface_get_arrays(s)
   var v=arr[Mesh.ARRAY_VERTEX] if mode<0 else mesh.surface_get_blend_shape_arrays(s)[mode][Mesh.ARRAY_VERTEX]
   var idx=arr[Mesh.ARRAY_INDEX];var mapped=PackedInt32Array()
   for p in v:
    var key=p.snapped(Vector3.ONE*.0001)
    if not ids.has(key):ids[key]=ids.size()
    mapped.append(ids[key])
   for k in range(0,idx.size(),3):
    var tri=[mapped[idx[k]],mapped[idx[k+1]],mapped[idx[k+2]]]
    if tri[0]==tri[1] or tri[1]==tri[2] or tri[0]==tri[2]:continue
    for j in range(3):
     var a=tri[j];var b=tri[(j+1)%3];var edge=Vector2i(mini(a,b),maxi(a,b));edges[edge]=edges.get(edge,0)+1
  var open=0
  for count in edges.values():
   if count==1:open+=1
  print("HEAD_BOUNDARIES mode=",mode," open=",open)
  if open>0:failures+=1
 for s in [6,7,8]:
  var tex=mesh.surface_get_material(s).get_shader_parameter("material_texture")
  if not tex.get_image().has_mipmaps():failures+=1
 var lod=ImporterMesh.from_mesh(mesh)
 print("HAIR_LOD_LEVELS ",lod.get_surface_lod_count(0))
 if lod.get_surface_lod_count(0)<1:failures+=1
 print("CLOSED_HEAD_TEST failures=",failures)
 quit(failures)
