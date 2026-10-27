extends SceneTree
var counts := {}
var material_paths := {
	"wall_wood":"res://assets/house_materials/wall_wood.tres",
	"floor_wood":"res://assets/house_materials/floor_wood.tres",
	"basement_wall":"res://assets/house_materials/basement_wall.tres",
	"basement_floor":"res://assets/house_materials/basement_floor.tres"
}
func _initialize() -> void: call_deferred("run")
func apply_surface(node: Node) -> void:
	if node is MeshInstance3D and node.mesh is BoxMesh:
		var size: Vector3 = node.mesh.size
		var pos: Vector3 = node.global_position
		var title: String = str(node.get_parent().name)
		var kind := ""
		if size.y < 0.01 and minf(size.x,size.z) < 0.02:
			node.visible=false
			counts["hidden_layout_grid"] = counts.get("hidden_layout_grid",0)+1
		elif is_equal_approx(minf(size.x,size.z),0.14):
			kind="basement_wall" if pos.y < -0.2 else "wall_wood"
		elif is_equal_approx(size.y,0.2) and size.x > 0.25 and size.z > 0.25:
			var landing: bool = is_equal_approx(size.x,4.0) and is_equal_approx(size.z,1.0)
			kind="basement_floor" if pos.y < -1.0 and not landing else "floor_wood"
		elif is_equal_approx(size.x,1.3) and is_equal_approx(size.y,0.12) and is_equal_approx(size.z,0.32):
			kind="floor_wood"
		elif (is_equal_approx(size.x,0.05) and is_equal_approx(size.z,0.05)) or (is_equal_approx(size.x,0.07) and is_equal_approx(size.y,0.07)):
			kind="wall_wood"
		elif title in ["LadderCover","Panel","BridgePlank","LandingGuard","SecretPassageRoof"]:
			kind="floor_wood"
		if not kind.is_empty():
			node.material_override=load(material_paths[kind])
			node.set_meta("house_surface",kind)
			counts[kind]=counts.get(kind,0)+1
	for child in node.get_children(): apply_surface(child)
func run() -> void:
	var house := load("res://scenes/horror/house_layout.tscn").instantiate() as Node3D
	house.process_mode=Node.PROCESS_MODE_DISABLED
	root.add_child(house)
	apply_surface(house)
	house.process_mode=Node.PROCESS_MODE_INHERIT
	var packed := PackedScene.new()
	packed.pack(house)
	var err := ResourceSaver.save(packed,"res://scenes/horror/house_layout.tscn")
	print("HOUSE_MATERIALS_SAVED ",err," ",counts)
	quit(err)
