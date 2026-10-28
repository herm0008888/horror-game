extends SceneTree
## Offline authoring: static batches never include collisions, moving storage, pickups or enemies.
const TARGET="res://assets/house_optimized/render/"
var report={"source_meshes_batched":0,"batch_instances":0,"lod_meshes":0,"lod_levels":0,"detail_ranges":0}
var lod_cache={}
var serial:=0
func _initialize(): call_deferred("run")
func own(node: Node,owner_node: Node):
	for c in node.get_children():
		c.owner=owner_node
		own(c,owner_node)
func lod(mesh: ArrayMesh) -> ArrayMesh:
	if lod_cache.has(mesh): return lod_cache[mesh]
	var source_mesh:=mesh
	var im=ImporterMesh.from_mesh(mesh)
	var missing=false
	for s in range(im.get_surface_count()):
		if im.get_surface_arrays(s)[Mesh.ARRAY_VERTEX].size()>96 and im.get_surface_lod_count(s)==0: missing=true
	if missing:
		im.generate_lods(60,0,[])
		mesh=im.get_mesh()
		report.lod_meshes+=1
		for s in range(im.get_surface_count()): report.lod_levels+=im.get_surface_lod_count(s)
	lod_cache[source_mesh]=mesh
	return mesh
func pose(node: Node) -> Transform3D:
	var result:=Transform3D.IDENTITY
	var cursor: Node=node
	while cursor:
		if cursor is Node3D: result=cursor.transform*result
		cursor=cursor.get_parent()
	return result
func opaque(mat: Material) -> bool:
	return mat is StandardMaterial3D and mat.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED
func batch(parent: Node3D,candidates: Array[MeshInstance3D],structural: bool=false):
	var groups={}
	for m in candidates:
		if not m.visible or not m.mesh or m.skin: continue
		var valid=true
		for s in range(m.mesh.get_surface_count()):
			if not opaque(m.get_active_material(s)): valid=false
		if not valid: continue
		var transform: Transform3D=pose(parent).affine_inverse()*pose(m)
		var center: Vector3=transform*m.get_aabb().get_center()
		var cell=Vector3i(floori(center.x/3),floori(center.y/3.4),floori(center.z/3)) if structural else Vector3i.ZERO
		for s in range(m.mesh.get_surface_count()):
			var mat: Material=m.get_active_material(s)
			var key=str(cell)+":"+str(mat.get_rid().get_id())+":"+str(m.cast_shadow)
			if not groups.has(key): groups[key]={"tool":SurfaceTool.new(),"mat":mat,"nodes":[],"shadow":m.cast_shadow}
			var g: Dictionary=groups[key]
			if g.nodes.is_empty(): g.tool.begin(Mesh.PRIMITIVE_TRIANGLES)
			g.tool.append_from(m.mesh,s,transform)
			if m not in g.nodes: g.nodes.append(m)
	var replaced={}
	for key in groups:
		var g: Dictionary=groups[key]
		if g.nodes.size()<2: continue
		var mesh: ArrayMesh=g.tool.commit()
		mesh=lod(mesh)
		serial+=1
		var path=TARGET+"batch_%04d.res"%serial
		ResourceSaver.save(mesh,path,ResourceSaver.FLAG_COMPRESS)
		var instance=MeshInstance3D.new()
		instance.name="StaticBatch%04d"%serial
		instance.mesh=load(path)
		instance.material_override=g.mat
		instance.cast_shadow=g.shadow
		instance.lod_bias=.7
		parent.add_child(instance)
		instance.owner=parent.owner if parent.owner else parent
		report.batch_instances+=1
		for original in g.nodes: replaced[original]=true
	# Only replace a source when every one of its surfaces was batched.
	# Singletons in a multi-surface source are emitted too, so nothing is lost.
	for key in groups:
		var g: Dictionary=groups[key]
		if g.nodes.size()!=1 or not replaced.has(g.nodes[0]): continue
		serial+=1
		var mesh: ArrayMesh=lod(g.tool.commit())
		var path=TARGET+"batch_%04d.res"%serial
		ResourceSaver.save(mesh,path,ResourceSaver.FLAG_COMPRESS)
		var instance=MeshInstance3D.new()
		instance.name="StaticBatch%04d"%serial
		instance.mesh=load(path)
		instance.material_override=g.mat
		instance.cast_shadow=g.shadow
		instance.lod_bias=.7
		parent.add_child(instance)
		instance.owner=parent.owner if parent.owner else parent
		report.batch_instances+=1
	for original in replaced:
		original.visible=false
		report.source_meshes_batched+=1
func flatten_static(node: Node):
	node.scene_file_path=""
	for child in node.get_children(): flatten_static(child)
func tune(node: Node):
	if node is MeshInstance3D and node.mesh is ArrayMesh and node.visible and not node.skin:
		node.mesh=lod(node.mesh)
		node.lod_bias=.7
		var size: Vector3=node.get_aabb().size*pose(node).basis.get_scale().abs()
		var longest=maxf(size.x,maxf(size.y,size.z))
		if longest<.45:
			node.visibility_range_end=16 if longest<.18 else 22
			node.visibility_range_end_margin=2
			report.detail_ranges+=1
	for c in node.get_children(): tune(c)
func run():
	DirAccess.make_dir_recursive_absolute(TARGET)
	var house=load("res://scenes/horror/house_layout.tscn").instantiate()
	house.process_mode=Node.PROCESS_MODE_DISABLED
	root.add_child(house)
	if house.has_node("StructuralBatches"):
		push_error("Already optimized. Run this authoring tool once on a clean scene.")
		quit(1)
		return
	# Work on each static prop separately to retain small occlusion bounds.
	for scene_path in ["ground_living_room","ground_kitchen_dining","ground_study","ground_utility_room","ground_front_store","ground_hall_and_landings","ground_architectural_details","basement_abandoned_cell","basement_rotten_storage","basement_dead_boiler_room","basement_ruined_workshop","basement_south_store","basement_escape_store","stone_workshop_decor","upper_master_bedroom","upper_east_bedroom","upper_south_bedroom","upper_bathroom","upper_upper_store","upper_upper_landing","upper_secret_service_passage","upper_cell_escape_upgrade"]:
		var path="res://scenes/horror/"+scene_path+".tscn"
		if not ResourceLoader.exists(path): continue
		var scene=load(path).instantiate()
		house.add_child(scene)
		for prop in scene.get_children():
			if not prop is Node3D or not prop.get_script()==null or prop.scene_file_path.contains("/furniture/"): continue
			var candidates: Array[MeshInstance3D]=[]
			for m in prop.find_children("*","MeshInstance3D",true,false): candidates.append(m)
			batch(prop,candidates)
			flatten_static(prop)
		tune(scene)
		# Owning only newly authored descendants preserves external moving furniture instances.
		for prop in scene.get_children():
			if prop.scene_file_path.is_empty(): own(prop,scene)
		var packed=PackedScene.new()
		assert(packed.pack(scene)==OK)
		assert(ResourceSaver.save(packed,path)==OK)
		house.remove_child(scene)
		scene.free()
	# Main structural meshes are batched by material in small spatial cells.
	var candidates: Array[MeshInstance3D]=[]
	for body in house.get_children():
		if body is StaticBody3D and body.get_script()==null and body.name not in ["BridgePlank","LadderCover","FrontDoorPlaceholder"]:
			var m=body.get_node_or_null("Mesh")
			if m is MeshInstance3D and m.visible: candidates.append(m)
	var batches=Node3D.new()
	batches.name="StructuralBatches"
	house.add_child(batches)
	batch(batches,candidates,true)
	own(batches,house)
	batches.owner=house
	house.process_mode=Node.PROCESS_MODE_INHERIT
	var packed=PackedScene.new()
	assert(packed.pack(house)==OK)
	assert(ResourceSaver.save(packed,"res://scenes/horror/house_layout.tscn")==OK)
	var lighting=load("res://scenes/horror/house_lighting.tscn").instantiate()
	for light in lighting.find_children("*","Light3D",true,false):
		light.distance_fade_enabled=true
		light.distance_fade_begin=18
		light.distance_fade_length=6
		light.distance_fade_shadow=14
	packed=PackedScene.new()
	packed.pack(lighting)
	ResourceSaver.save(packed,"res://scenes/horror/house_lighting.tscn")
	lighting.free()
	FileAccess.open("res://docs/render_optimization_report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("OPTIMIZED ",JSON.stringify(report))
	house.free()
	quit()




