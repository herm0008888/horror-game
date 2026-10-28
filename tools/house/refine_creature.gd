extends SceneTree
func _initialize(): call_deferred("run")
func weld_key(v: Vector3) -> Vector3i: return Vector3i(roundi(v.x*10000),roundi(v.y*10000),roundi(v.z*10000))
func root_id(parents: Array[int],i: int) -> int:
	while parents[i]!=i: i=parents[i]
	return i
func refine(source: ArrayMesh) -> ArrayMesh:
	var result=ArrayMesh.new()
	result.blend_shape_mode=source.blend_shape_mode
	for b in range(source.get_blend_shape_count()): result.add_blend_shape(source.get_blend_shape_name(b))
	for s in range(source.get_surface_count()):
		var arrays=source.surface_get_arrays(s)
		var blends=source.surface_get_blend_shape_arrays(s)
		if s==5:
			var verts: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
			var parents: Array[int]=[]
			var weld={}
			for i in range(verts.size()):
				var key=weld_key(verts[i])
				parents.append(weld.get(key,i))
				weld[key]=parents[i]
			for i in range(0,indices.size(),3):
				for j in [1,2]: parents[root_id(parents,indices[i+j])]=root_id(parents,indices[i])
			var groups={}
			for i in range(verts.size()):
				var id=root_id(parents,i)
				if not groups.has(id): groups[id]=[]
				groups[id].append(i)
			print("DENTITION_COMPONENTS ",groups.size())
			for group in groups.values():
				var center=Vector3.ZERO
				for i in group: center+=verts[i]
				center/=group.size()
				for i in group:
					var v=verts[i]-center
					# Short irregular worn incisors replace long cylindrical pegs.
					v.y*=.58
					v.z*=.62
					v.x*=1.16
					verts[i]=center+v
				for blend in blends:
					var points: PackedVector3Array=blend[Mesh.ARRAY_VERTEX]
					if points.is_empty(): continue
					var pivot=Vector3.ZERO
					for i in group: pivot+=points[i]
					pivot/=group.size()
					for i in group:
						var v=points[i]-pivot
						v.y*=.58
						v.z*=.62
						v.x*=1.16
						points[i]=pivot+v
					blend[Mesh.ARRAY_VERTEX]=points
			arrays[Mesh.ARRAY_VERTEX]=verts
		result.add_surface_from_arrays(source.surface_get_primitive_type(s),arrays,blends)
		var mat=source.surface_get_material(s)
		if s==5:
			var enamel=StandardMaterial3D.new()
			enamel.albedo_texture=load("res://assets/horror/visitation_visceral_teeth_albedo.png")
			enamel.albedo_color=Color(.46,.43,.34)
			enamel.roughness=.88
			enamel.metallic_specular=.12
			mat=enamel
		result.surface_set_material(s,mat)
	return result
func run():
	var enemy=load("res://scenes/horror/visitation.tscn").instantiate()
	var meshes=enemy.get_node("Figure").find_children("*","MeshInstance3D",true,false)
	for m in meshes:
		if not m.mesh is ArrayMesh or m.mesh.get_surface_count()!=8: continue
		var mesh=refine(m.mesh)
		ResourceSaver.save(mesh,"res://assets/horror/visitor_refined.res",ResourceSaver.FLAG_COMPRESS)
		m.mesh=load("res://assets/horror/visitor_refined.res")
	var pack=PackedScene.new()
	pack.pack(enemy)
	ResourceSaver.save(pack,"res://scenes/horror/visitation.tscn")
	enemy.free()
	quit()
