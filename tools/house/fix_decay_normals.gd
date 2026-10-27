extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var decor: Node3D=load("res://scenes/horror/basement_decay.tscn").instantiate()
	for node in decor.get_children():
		if not node is MeshInstance3D or not node.mesh is ArrayMesh: continue
		var arrays: Array=node.mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		var st:=SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		st.set_smooth_group(-1)
		if indices.size()>0:
			for index in indices: st.add_vertex(vertices[index])
		else:
			for v in vertices: st.add_vertex(v)
		st.generate_normals()
		node.mesh=st.commit()
	var packed:=PackedScene.new()
	packed.pack(decor)
	ResourceSaver.save(packed,"res://scenes/horror/basement_decay.tscn")
	decor.free()
	quit()

