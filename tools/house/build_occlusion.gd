extends SceneTree
## Rebuild after structural edits. Occluders stay strictly inside opaque static walls/slabs.
var vertices: Array[PackedVector3Array]=[PackedVector3Array(),PackedVector3Array(),PackedVector3Array()]
var indices: Array[PackedInt32Array]=[PackedInt32Array(),PackedInt32Array(),PackedInt32Array()]
var counts: Array[int]=[0,0,0]
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var house: Node3D=load("res://scenes/horror/house_layout.tscn").instantiate()
	house.process_mode=Node.PROCESS_MODE_DISABLED
	root.add_child(house)
	if house.has_node("HouseOcclusion"):
		var old:=house.get_node("HouseOcclusion")
		house.remove_child(old)
		old.free()
	for body in house.get_children():
		if not body is StaticBody3D: continue
		if body.name in ["BridgePlank","LadderCover","FrontDoorPlaceholder"]: continue
		var visual:=body.get_node_or_null("Mesh") as MeshInstance3D
		var collision:=body.get_node_or_null("Collision") as CollisionShape3D
		if not visual or not collision or not collision.shape is BoxShape3D: continue
		if not visual.get_meta("house_surface","") in ["wall_wood","floor_wood","basement_wall","basement_floor"]: continue
		var dimensions: Vector3=collision.shape.size-Vector3.ONE*0.12
		if dimensions.min_axis_index()==-1 or minf(dimensions.x,minf(dimensions.y,dimensions.z))<=0: continue
		if maxf(dimensions.x,dimensions.z)<0.6: continue
		var level:=0 if body.position.y< -0.2 else (1 if body.position.y<3.2 else 2)
		var box:=BoxMesh.new()
		box.size=dimensions
		var data:=box.get_mesh_arrays()
		var points: PackedVector3Array=data[Mesh.ARRAY_VERTEX]
		var triangles: PackedInt32Array=data[Mesh.ARRAY_INDEX]
		var offset:=vertices[level].size()
		for point in points: vertices[level].append(collision.global_transform*point)
		for index in triangles: indices[level].append(index+offset)
		counts[level]+=1
	var group:=Node3D.new()
	group.name="HouseOcclusion"
	group.set_meta("rebuild_tool","res://tools/house/build_occlusion.gd")
	for i in range(3):
		var occluder:=ArrayOccluder3D.new()
		occluder.set_arrays(vertices[i],indices[i])
		var node:=OccluderInstance3D.new()
		node.name=["BasementSolidWalls","GroundSolidWalls","UpperSolidWalls"][i]
		node.occluder=occluder
		group.add_child(node)
		node.owner=group
	var packed:=PackedScene.new()
	packed.pack(group)
	ResourceSaver.save(packed,"res://scenes/horror/house_occlusion.tscn")
	group.free()
	var instance: Node=load("res://scenes/horror/house_occlusion.tscn").instantiate()
	house.add_child(instance)
	instance.owner=house
	house.process_mode=Node.PROCESS_MODE_INHERIT
	packed=PackedScene.new()
	packed.pack(house)
	ResourceSaver.save(packed,"res://scenes/horror/house_layout.tscn")
	print("OCCLUDERS_SAVED ",counts)
	house.free()
	quit()
