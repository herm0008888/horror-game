extends SceneTree
# Editor authoring tool. All output is saved geometry, never generated during play.
var rng := RandomNumberGenerator.new()
var decor: Node3D
var brick: Material
var iron: Material
var plaster: Material
func _initialize() -> void: call_deferred("run")
func add_mesh(title: String, mesh: Mesh, pos: Vector3, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name=title
	node.mesh=mesh
	node.material_override=material
	decor.add_child(node)
	node.owner=decor
	node.position=pos
	return node
func shard(size: Vector3) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var points: Array[Vector3]=[]
	for i in range(9):
		var a := TAU*i/9.0
		var r := rng.randf_range(0.7,1.0)
		points.append(Vector3(cos(a)*size.x*0.5*r,sin(a)*size.y*0.5*r,0))
	for i in range(9):
		var a := points[i]
		var b := points[(i+1)%9]
		var back := Vector3(0,0,-size.z)
		for v in [Vector3.ZERO,b,a,a,b,b+back,a,b+back,a+back,back,a+back,b+back]: st.add_vertex(v)
	st.generate_normals()
	return st.commit()
func pipe(a: Vector3,b: Vector3, radius: float, title: String) -> void:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius=radius
	cylinder.bottom_radius=radius
	cylinder.height=a.distance_to(b)
	cylinder.radial_segments=10
	var node := add_mesh(title,cylinder,(a+b)*0.5,iron)
	var direction := (b-a).normalized()
	var axis := Vector3.UP.cross(direction)
	if axis.length()>0.01: node.quaternion=Quaternion(axis.normalized(),acos(Vector3.UP.dot(direction)))
func run() -> void:
	rng.seed=281026
	brick=load("res://assets/house_materials/exposed_brick.tres")
	iron=load("res://assets/house_materials/rusted_iron.tres")
	plaster=load("res://assets/house_materials/basement_wall.tres")
	var house := load("res://scenes/horror/house_layout.tscn").instantiate() as Node3D
	house.process_mode=Node.PROCESS_MODE_DISABLED
	root.add_child(house)
	if house.has_node("BasementDecay"):
		push_error("Basement already authored; restore source before regenerating.")
		quit(1)
		return
	decor=Node3D.new()
	decor.name="BasementDecay"
	house.add_child(decor)
	var bar_material := house.get_node("CellBar/Mesh").material_override as Material
	var wall_count := 0
	var bars := 0
	for body in house.get_children():
		if not body is Node3D or body.position.y>=-0.25: continue
		for node in body.get_children():
			if not node is MeshInstance3D: continue
			if node.material_override==bar_material or body.name=="GateLock":
				node.material_override=iron
				bars+=1
			if node.get_meta("house_surface","")!="basement_wall" or not node.mesh is BoxMesh: continue
			var size: Vector3=node.mesh.size
			var along_x := size.x>size.z
			var length: float=maxf(size.x,size.z)
			# Subdivided solid wall: uneven plaster, chipped jambs and broken top edges.
			var box := BoxMesh.new()
			box.size=size
			box.subdivide_width=clampi(int(size.x*4),1,64)
			box.subdivide_height=clampi(int(size.y*4),1,16)
			box.subdivide_depth=clampi(int(size.z*4),1,64)
			var arrays := box.get_mesh_arrays()
			var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			for i in range(vertices.size()):
				var v := vertices[i]
				var wave := sin(v.x*37.1+v.y*19.3+v.z*27.7)*sin(v.y*14.1+v.x*11.9)
				v.x+=wave*0.045
				v.z+=wave*0.045
				v.y+=sin(v.x*23.0+v.z*31.0)*0.045
				vertices[i]=v
			arrays[Mesh.ARRAY_VERTEX]=vertices
			var mesh := ArrayMesh.new()
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
			node.mesh=mesh
			wall_count+=1
			# Broken plaster patches with irregular silhouettes on both faces.
			if length<0.6 or size.y<0.6: continue
			for side in [-1.0,1.0]:
				for n in range(clampi(int(length/1.8),1,5)):
					var offset := rng.randf_range(-length*0.38,length*0.38)
					var pos: Vector3=body.position+Vector3(offset if along_x else side*(size.x*0.5+0.055),rng.randf_range(-size.y*0.25,size.y*0.22),side*(size.z*0.5+0.055) if along_x else offset)
					var patch := add_mesh("ExposedMasonry_%d_%s_%d"%[wall_count,str(side),n],shard(Vector3(minf(length*0.75,rng.randf_range(0.7,1.8)),rng.randf_range(0.5,1.4),0.065)),pos,brick)
					patch.rotation.y=(0.0 if side>0 else PI) if along_x else (PI*0.5 if side>0 else -PI*0.5)
				# Low rubble hugs wall bases; walking routes and doors stay open.
				if size.y>2.0:
					for n in range(4):
						var offset := rng.randf_range(-length*0.42,length*0.42)
						var pos: Vector3 = body.position+Vector3(offset if along_x else side*(size.x*0.5+0.15),0,side*(size.z*0.5+0.15) if along_x else offset)
						pos.y=-3.35+rng.randf_range(0,0.07)
						var chunk := add_mesh("FallenPlaster_%d_%s_%d"%[wall_count,str(side),n],shard(Vector3(rng.randf_range(0.12,0.38),rng.randf_range(0.12,0.35),0.06)),pos,plaster if n%2==0 else brick)
						chunk.rotation=Vector3(-PI/2,rng.randf_range(-PI,PI),0)
	# Visible corroded plumbing and wall brackets in the starting cell.
	pipe(Vector3(4.18,-0.65,12.3),Vector3(4.18,-0.65,15.7),0.055,"CorrodedCeilingPipe")
	pipe(Vector3(4.18,-0.65,15.7),Vector3(4.18,-2.9,15.7),0.055,"BrokenDrain")
	pipe(Vector3(4.18,-2.9,15.7),Vector3(4.48,-2.9,15.7),0.055,"DrainOutlet")
	for z in [12.6,13.8,15.1]:
		pipe(Vector3(4.08,-0.65,z),Vector3(4.28,-0.65,z),0.078,"PipeCollar")
	# Rusted bolts at the grid intersections, all individually editable.
	for x in [4.1,5.4,6.6,7.88]:
		for y in [-3.2,-1.9,-0.4]: pipe(Vector3(x,y,11.92),Vector3(x,y,12.1),0.045,"GateRivet")
	var packed := PackedScene.new()
	packed.pack(decor)
	ResourceSaver.save(packed,"res://scenes/horror/basement_decay.tscn")
	house.remove_child(decor)
	decor.free()
	var instance: Node = load("res://scenes/horror/basement_decay.tscn").instantiate()
	house.add_child(instance)
	instance.owner=house
	house.process_mode=Node.PROCESS_MODE_INHERIT
	packed=PackedScene.new()
	packed.pack(house)
	ResourceSaver.save(packed,"res://scenes/horror/house_layout.tscn")
	print("BASEMENT_DECAY walls=",wall_count," rusted_metal=",bars," saved scene")
	quit()

