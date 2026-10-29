extends SceneTree
## Offline optimization. Source scenes remain in scenes/authoring.
var groups: Dictionary
func _initialize() -> void: call_deferred("run")
func collect(node: Node, transform: Transform3D) -> void:
	var local := transform
	if node is Node3D: local = transform * node.transform
	if node is MeshInstance3D and node.mesh:
		for surface in range(node.mesh.get_surface_count()):
			var material: Material = node.get_active_material(surface)
			var key := material.get_instance_id() if material else 0
			if not groups.has(key):
				var tool := SurfaceTool.new()
				tool.begin(Mesh.PRIMITIVE_TRIANGLES)
				tool.set_material(material)
				groups[key] = tool
			groups[key].append_from(node.mesh, surface, local)
	for child in node.get_children(): collect(child, local)
func clear_visuals(node: Node) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			child.free()
		else: clear_visuals(child)
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://scenes/authoring")
	DirAccess.make_dir_recursive_absolute("res://assets/optimized")
	for path in ["scenes/props/warehouse.tscn", "scenes/props/container.tscn", "assets/vehicles/coupe_body.glb", "assets/vehicles/wheel.glb"]:
		var authoring_path: String = "res://scenes/authoring/" + path.get_file()
		var source_path: String = authoring_path if path.ends_with(".tscn") and FileAccess.file_exists(authoring_path) else "res://" + path
		var source := load(source_path) as PackedScene
		var instance := source.instantiate()
		root.add_child(instance)
		groups = {}
		collect(instance, Transform3D.IDENTITY)
		var merged := ArrayMesh.new()
		for tool in groups.values(): tool.commit(merged)
		var name: String = path.get_file().get_basename()
		var mesh_path: String = "res://assets/optimized/" + name + ".res"
		ResourceSaver.save(merged, mesh_path)
		if path.ends_with(".tscn"):
			if not FileAccess.file_exists(authoring_path):
				DirAccess.copy_absolute("res://" + path, authoring_path)
			clear_visuals(instance)
		else:
			instance.free()
			instance = Node3D.new()
			instance.name = name
			root.add_child(instance)
		var visual := MeshInstance3D.new()
		visual.name = "BakedVisual"
		visual.mesh = load(mesh_path)
		instance.add_child(visual)
		visual.owner = instance
		var packed := PackedScene.new()
		packed.pack(instance)
		var destination: String = "res://" + path if path.ends_with(".tscn") else "res://scenes/vehicle/" + name + "_visual.tscn"
		ResourceSaver.save(packed, destination)
		print("BAKED ", name, " surfaces ", merged.get_surface_count())
		instance.free()
	quit()
