extends SceneTree
var mapping: Dictionary={}
func _initialize() -> void: call_deferred("run")
func visit(node: Node) -> void:
	if node is MeshInstance3D and node.mesh is ArrayMesh:
		var mesh: ArrayMesh=node.mesh
		var source:=mesh.resource_path
		var vertices:=0
		for surface in range(mesh.get_surface_count()): vertices+=mesh.surface_get_array_len(surface)
		if source.begins_with("res://scenes/horror/basement_") and "::" in source and vertices>=512 and not mapping.has(source):
			var temp: String="res://assets/house_optimized/mesh_pending.res"
			ResourceSaver.save(mesh,temp,ResourceSaver.FLAG_COMPRESS)
			var path: String="res://assets/house_optimized/mesh_"+FileAccess.get_sha256(temp).left(24)+".res"
			if not FileAccess.file_exists(path): DirAccess.copy_absolute(temp,path)
			mapping[source]=path
	for child in node.get_children(): visit(child)
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/house_optimized")
	for title in ["abandoned_cell","rotten_storage","dead_boiler_room","ruined_workshop","south_store","escape_store","decay"]:
		var scene: Node=load("res://scenes/horror/basement_"+title+".tscn").instantiate()
		visit(scene)
		scene.free()
	var file:=FileAccess.open("res://tools/house/compact_mesh_map.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(mapping,"  "))
	DirAccess.remove_absolute("res://assets/house_optimized/mesh_pending.res")
	print("LOSSLESS_MESH_EXPORTS ",mapping.size())
	quit()
