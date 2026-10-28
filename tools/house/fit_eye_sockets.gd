extends SceneTree
func _initialize(): call_deferred("run")
func fit(v: Vector3) -> Vector3:
	if v.y<1.70 or v.y>2.13 or v.z>-.08: return v
	var center=Vector3(.108 if v.x>=0 else -.108,1.90,v.z)
	var d=Vector2(v.x-center.x,v.y-center.y).length()
	var weight=(1-smoothstep(.12,.20,d))*smoothstep(.012,.045,absf(v.x))
	v.x=lerpf(v.x,center.x+(v.x-center.x)*.62,weight)
	v.y=lerpf(v.y,center.y+(v.y-center.y)*.62,weight)
	return v
func run():
	var e=load("res://scenes/horror/visitation.tscn").instantiate()
	var s: Skeleton3D=e.find_skeleton(e.get_node("Figure"))
	var socket=s.get_node("RecessedSockets")
	for i in range(2): socket.get_child(i).scale*=Vector3(.72,.72,1)
	for m in e.get_node("Figure").find_children("*","MeshInstance3D",true,false):
		if not m.mesh is ArrayMesh or m.mesh.get_surface_count()!=8: continue
		var original: ArrayMesh=m.mesh
		var mesh=ArrayMesh.new()
		mesh.blend_shape_mode=original.blend_shape_mode
		for i in range(original.get_blend_shape_count()): mesh.add_blend_shape(original.get_blend_shape_name(i))
		for i in range(original.get_surface_count()):
			var arrays=original.surface_get_arrays(i)
			var blends=original.surface_get_blend_shape_arrays(i)
			if i==1:
				var verts: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
				for k in range(verts.size()): verts[k]=fit(verts[k])
				arrays[Mesh.ARRAY_VERTEX]=verts
				if original.blend_shape_mode==Mesh.BLEND_SHAPE_MODE_NORMALIZED:
					for blend in blends:
						var points: PackedVector3Array=blend[Mesh.ARRAY_VERTEX]
						for k in range(points.size()): points[k]=fit(points[k])
						blend[Mesh.ARRAY_VERTEX]=points
			mesh.add_surface_from_arrays(original.surface_get_primitive_type(i),arrays,blends)
			mesh.surface_set_material(i,original.surface_get_material(i))
		ResourceSaver.save(mesh,"res://assets/horror/visitor_refined_sockets.res",ResourceSaver.FLAG_COMPRESS)
		m.mesh=load("res://assets/horror/visitor_refined_sockets.res")
	var pack=PackedScene.new()
	pack.pack(e)
	ResourceSaver.save(pack,"res://scenes/horror/visitation.tscn")
	e.free()
	quit()
