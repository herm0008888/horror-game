extends SceneTree
# Run once to author independent, editable room scenes. Nothing spawns at runtime.
const LIB="res://assets/house_library/"
var rooms: Node3D
var current: Node3D
var rng := RandomNumberGenerator.new()
var models := {}
var materials := {}
var count := 0
func _initialize() -> void: call_deferred("run")
func own(node: Node, target: Node) -> void:
	for child in node.get_children():
		child.owner=target
		own(child,target)
func gather(node: Node, transform: Transform3D, result: Array[AABB]) -> void:
	var t := transform
	if node is Node3D: t=transform*node.transform
	if node is MeshInstance3D and node.mesh: result.append(t*node.get_aabb())
	for child in node.get_children(): gather(child,t,result)
func weather(node: Node) -> void:
	if node is MeshInstance3D:
		for i in range(node.mesh.get_surface_count()):
			var original: Material=node.get_active_material(i)
			if original is StandardMaterial3D:
				if not materials.has(original):
					var mat: StandardMaterial3D=original.duplicate()
					mat.albedo_color=Color(0.64,0.61,0.54)
					mat.roughness=0.94
					mat.metallic_specular=0.12
					materials[original]=mat
				node.set_surface_override_material(i,materials[original])
	for child in node.get_children(): weather(child)
func prop(id: String,pos: Vector3,size: float,angle: float=0.0,solid: bool=true,flat: bool=false) -> Node3D:
	if not models.has(id): models[id]=load(LIB+id+"/"+id+".gltf")
	var wrapper: Node3D=StaticBody3D.new() if solid else Node3D.new()
	wrapper.name=id.to_pascal_case()
	current.add_child(wrapper)
	var model: Node3D=models[id].instantiate()
	model.name="Model"
	wrapper.add_child(model)
	var boxes: Array[AABB]=[]
	gather(model,Transform3D.IDENTITY,boxes)
	var bounds := boxes[0]
	for b in boxes: bounds=bounds.merge(b)
	var factor := size/maxf(maxf(bounds.size.x,bounds.size.z) if flat else bounds.size.y,0.01)
	model.scale*=factor
	model.position-=Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)*factor
	weather(model)
	if solid:
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size=bounds.size*factor
		collision.shape=shape
		collision.position.y=shape.size.y*0.5
		wrapper.add_child(collision)
	wrapper.position=pos
	wrapper.rotation.y=angle
	wrapper.set_meta("source","https://polyhaven.com/a/"+id)
	count+=1
	return wrapper
func mesh_node(title: String,mesh: Mesh,pos: Vector3,mat: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name=title
	node.mesh=mesh
	node.material_override=mat
	current.add_child(node)
	node.position=pos
	return node
func beam(a: Vector3,b: Vector3,width: float,mat: Material,title: String) -> void:
	var box := BoxMesh.new()
	box.size=Vector3(width,width,a.distance_to(b))
	var node := mesh_node(title,box,(a+b)/2,mat)
	node.look_at(b,Vector3.UP)
func rubble(pos: Vector3,extent: Vector2,mat: Material) -> void:
	# Uneven low mound, textured with the downloaded concrete rubble scan.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var points: Array[Vector3]=[]
	for i in range(15):
		var a:=TAU*i/15.0
		points.append(Vector3(cos(a)*extent.x*rng.randf_range(0.7,1),0,sin(a)*extent.y*rng.randf_range(0.7,1)))
	for i in range(15):
		for v in [Vector3(0,rng.randf_range(0.10,0.22),0),points[i],points[(i+1)%15]]: st.add_vertex(v)
	st.generate_normals()
	mesh_node("CollapsedMasonry",st.commit(),pos,mat)
func room(title: String) -> void:
	current=Node3D.new()
	current.name=title
	rooms.add_child(current)
func run() -> void:
	rng.seed=281028
	var house: Node3D=load("res://scenes/horror/house_layout.tscn").instantiate()
	house.process_mode=Node.PROCESS_MODE_DISABLED
	root.add_child(house)
	if house.has_node("BasementDressing"):
		push_error("Already furnished")
		quit(1)
		return
	rooms=Node3D.new()
	rooms.name="BasementDressing"
	house.add_child(rooms)
	var wood: Material=load("res://assets/house_materials/floor_wood.tres")
	var iron: Material=load("res://assets/house_materials/rusted_iron.tres")
	var debris: Material=load("res://assets/house_materials/basement_rubble.tres")
	room("AbandonedCell")
	prop("old_bed_frame",Vector3(7.35,-3.4,14.45),2.2,0,true,true)
	prop("metal_trash_can",Vector3(7.55,-3.4,12.8),0.62)
	prop("can_rusted",Vector3(7.0,-3.4,13.1),0.17,0,false)
	prop("trashbag",Vector3(4.6,-3.4,12.65),0.40,0.6,false)
	prop("trashbag",Vector3(4.8,-3.4,12.9),0.30,-0.4,false)
	rubble(Vector3(4.22,-3.39,13.6),Vector2(0.20,0.65),debris)
	rubble(Vector3(7.8,-3.39,15.55),Vector2(0.16,0.32),debris)
	room("RottenStorage")
	prop("wooden_bookshelf_worn",Vector3(0.5,-3.4,2.3),1.95,PI/2)
	prop("wooden_crate_01",Vector3(1.25,-3.4,0.65),0.65,0.12)
	prop("wooden_crate_02",Vector3(1.25,-2.75,0.65),0.43,-0.16)
	prop("cardboard_box_01",Vector3(3.7,-3.4,0.7),0.6,-0.25)
	prop("painted_wooden_chair_02",Vector3(4.9,-3.4,4.9),0.95,0.8)
	prop("vintage_suitcase",Vector3(0.75,-3.4,4.4),0.35,0.3)
	prop("trashbag",Vector3(5.55,-3.4,0.6),0.55)
	prop("trashbag",Vector3(5.3,-3.4,0.9),0.4)
	rubble(Vector3(0.3,-3.39,5.3),Vector2(0.23,0.58),debris)
	room("DeadBoilerRoom")
	prop("barrel_stove",Vector3(7.0,-3.4,0.85),1.4,PI/2)
	prop("utility_box_01",Vector3(11.7,-1.9,4.7),0.65,-PI/2,false)
	prop("metal_toolbox",Vector3(7.0,-3.4,4.9),0.32)
	prop("plastic_bottle_gallon",Vector3(7.5,-3.4,5.5),0.32,0,false)
	prop("wooden_crate_02",Vector3(11.2,-3.4,5.3),0.6)
	rubble(Vector3(6.3,-3.39,1.5),Vector2(0.2,0.6),debris)
	room("RuinedWorkshop")
	prop("metal_tool_chest",Vector3(15.45,-3.4,5.0),1.25,-PI/2)
	prop("painted_wooden_table",Vector3(14.1,-3.4,0.65),0.85,0)
	prop("cross_pein_hammer",Vector3(14.0,-2.54,0.65),0.36,0.5,false,true)
	prop("handsaw_wood",Vector3(14.45,-2.54,0.65),0.48,-0.5,false,true)
	prop("painted_wooden_stool",Vector3(15.0,-3.4,1.6),0.55,0.3)
	prop("metal_trash_can",Vector3(15.4,-3.4,7.0),0.7)
	prop("trashbag",Vector3(14.8,-3.4,7.1),0.45)
	prop("cardboard_box_01",Vector3(12.5,-3.4,10.9),0.65,0.2)
	prop("can_rusted",Vector3(13.0,-3.4,11.4),0.2,0,false)
	rubble(Vector3(15.75,-3.39,9.8),Vector2(0.19,0.9),debris)
	room("SouthStore")
	prop("painted_wooden_cabinet",Vector3(10.1,-3.4,15.6),1.5,PI)
	prop("wooden_crate_01",Vector3(8.65,-3.4,13.6),0.65,0.15)
	prop("metal_toolbox",Vector3(8.65,-2.75,13.6),0.25)
	prop("wooden_crate_02",Vector3(13.6,-3.4,15.25),0.6,-0.4)
	prop("trashbag",Vector3(14.4,-3.4,15.5),0.5)
	prop("trashbag",Vector3(14.8,-3.4,15.6),0.32,0.3)
	prop("painted_wooden_chair_01",Vector3(11.9,-3.4,15.1),0.9,-0.4)
	room("EscapeStore")
	prop("wooden_crate_02",Vector3(0.65,-3.4,13.0),0.55)
	prop("cardboard_box_01",Vector3(0.65,-2.85,13.0),0.35)
	prop("trashbag",Vector3(0.5,-3.4,15.5),0.45)
	room("BrokenCeilingAndFrames")
	# Broken beams stop short of passages, with clear headroom above the route.
	for z in [2.0,5.0,9.0,14.8]:
		beam(Vector3(0.15,-0.24,z),Vector3(3.75,-0.39,z+0.08),0.17,wood,"SaggingJoist")
		beam(Vector3(8.25,-0.24,z),Vector3(11.7,-0.34,z-0.09),0.15,wood,"RottenJoist")
	for z in [0.8,1.2,4.0,4.3,8.3,8.6,10.2]:
		beam(Vector3(12.3,-0.3,z),Vector3(14.0,-0.65,z+0.2),0.1,wood,"SplinteredCeilingLath")
	for x in [8.6,9.0]: beam(Vector3(x,-0.5,0.2),Vector3(x,-0.6,5.7),0.07,iron,"RustyServiceConduit")
	# Crooked jamb liners frame real existing openings without narrowing the route.
	for data in [[6.0,3.5,false],[12.0,8.5,false],[13.0,12.0,true],[9.0,6.0,true],[2.0,12.0,true]]:
		var center:=Vector3(data[0],-3.4,data[1])
		var axis:=Vector3.RIGHT if data[2] else Vector3.BACK
		for side in [-1,1]: beam(center+axis*0.72*side,center+axis*0.75*side+Vector3(0,2.35,0),0.12,wood,"SplitDoorJamb")
		beam(center-axis*0.82+Vector3(0,2.4,0),center+axis*0.82+Vector3(0,2.34,0),0.18,wood,"CrackedLintel")
	# Separate room scenes retain transforms, materials and collisions in the editor.
	for child in rooms.get_children():
		own(child,child)
		var packed:=PackedScene.new()
		packed.pack(child)
		var path: String="res://scenes/horror/basement_"+str(child.name).to_snake_case()+".tscn"
		ResourceSaver.save(packed,path)
		rooms.remove_child(child)
		child.free()
		var instance: Node=load(path).instantiate()
		rooms.add_child(instance)
		instance.owner=rooms
	var packed:=PackedScene.new()
	packed.pack(rooms)
	ResourceSaver.save(packed,"res://scenes/horror/basement_dressing.tscn")
	house.remove_child(rooms)
	rooms.free()
	var instance: Node=load("res://scenes/horror/basement_dressing.tscn").instantiate()
	house.add_child(instance)
	instance.owner=house
	for node in house.get_children():
		if node is Label3D and node.position.y<0: node.visible=false
	house.process_mode=Node.PROCESS_MODE_INHERIT
	packed=PackedScene.new()
	packed.pack(house)
	ResourceSaver.save(packed,"res://scenes/horror/house_layout.tscn")
	print("BASEMENT_FURNISHED props=",count," room_scenes=7")
	quit()
