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
	if id=="portable_cassette_player": model.rotation.x=-PI/2
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
# Ground-floor furnishing is authored into editable scenes, with measured model bounds.
var house: Node3D
var wood: Material
var plaster: Material
var placements: Array[Dictionary]=[]
func p(id: String,x: float,z: float,height: float,yaw: float=0,y: float=0,solid: bool=true,flat: bool=false) -> Node3D:
	var n:=prop(id,Vector3(x,y,z),height,deg_to_rad(yaw),solid,flat)
	var a: Array[AABB]=[]
	gather(n.get_node("Model"),Transform3D.IDENTITY,a)
	var b:=a[0]
	for box in a: b=b.merge(box)
	var target:=b.size
	# Furniture dimensions are specified independently: lowering a cabinet must not shrink its width.
	if id=="painted_wooden_cabinet": target=Vector3(1.20,height,0.60)
	elif id=="painted_wooden_cabinet_02": target=Vector3(1.20,height,0.65)
	elif id=="electric_stove": target=Vector3(0.60,height,0.65)
	elif id=="painted_wooden_nightstand": target=Vector3(.62,height,.58)
	elif id=="painted_wooden_table" and height<.6: target=Vector3(1.45,height,.72)
	var ratio:=target/b.size
	var visual: Node3D=n.get_node("Model")
	visual.scale*=ratio
	visual.position*=ratio
	for child in n.get_children():
		if child is CollisionShape3D:
			child.shape.size=target
			child.position.y=target.y/2
	b.size=target
	n.set_meta("dimensions",target)
	n.set_meta("asset_id",id)
	n.set_meta("support_y",y)
	placements.append({"room":str(current.name),"asset":id,"position":[x,y,z],"yaw":yaw,"size":[b.size.x,b.size.y,b.size.z]})
	return n
func surface(n: Node3D,dx: float,dz: float,below: float=10) -> Vector3:
	# Ray against the real mesh, not the furniture's coarse collision box.
	var origin:=n.to_global(Vector3(dx,below,dz))
	var best: float=-100
	for mesh in n.find_children("*","MeshInstance3D",true,false):
		var faces: PackedVector3Array=mesh.mesh.get_faces()
		for i in range(0,faces.size(),3):
			var hit=Geometry3D.segment_intersects_triangle(origin,origin-Vector3(0,20,0),mesh.global_transform*faces[i],mesh.global_transform*faces[i+1],mesh.global_transform*faces[i+2])
			if hit!=null: best=maxf(best,hit.y)
	assert(best>-10,"No support surface on "+str(n.name))
	return Vector3(origin.x,best+0.001,origin.z)
func on(n: Node3D,id: String,dx: float,dz: float,size: float,yaw: float=0,flat: bool=false,below: float=10) -> Node3D:
	var pos:=surface(n,dx,dz,below)
	return p(id,pos.x,pos.z,size,yaw,pos.y,false,flat)
func piece(title: String,pos: Vector3,size: Vector3,mat: Material) -> MeshInstance3D:
	var mesh:=BoxMesh.new()
	mesh.size=size
	return mesh_node(title,mesh,pos,mat)
func rug(x: float,z: float,sx: float,sz: float):
	var mat:=StandardMaterial3D.new()
	mat.albedo_texture=load(LIB+"dirty_carpet/Diffuse.jpg")
	mat.albedo_color=Color(0.42,0.34,0.26)
	mat.roughness=1
	mat.uv1_scale=Vector3(2,2,2)
	piece("ThreadbareRug",Vector3(x,0.009,z),Vector3(sx,0.014,sz),mat)
func bookcase(x: float,z: float,yaw: float):
	var shelf:=p("wooden_bookshelf_worn",x,z,2.06,yaw)
	# All four rows rest on scanned shelf surfaces. The fifth remains partly empty.
	for level in [0.4,0.8,1.2,1.6]:
		on(shelf,"book_encyclopedia_set_01",-0.20,0.01,0.26,yaw,false,level)
	on(shelf,"standing_picture_frame_01",0.36,0.03,0.22,yaw-90,false,1.95)
	return shelf
func conceal(title: String,yaw: float):
	var old: Node3D=house.get_node(title)
	for child in old.get_children():
		if child is MeshInstance3D: child.visible=false
	var n:=p("painted_wooden_cabinet_02",old.position.x,old.position.z,2.4,yaw,0,false)
	var dim: Vector3=n.get_meta("dimensions")
	n.get_node("Model").scale*=Vector3(1.3,2.4,0.5)/dim
	n.set_meta("dimensions",Vector3(1.3,2.4,0.5))
func edge_debris(x: float,z: float,length: float,angle: float=0):
	for i in range(9):
		var off:=Vector3(rng.randf_range(-length/2,length/2),0,rng.randf_range(-0.12,0.12)).rotated(Vector3.UP,angle)
		var node:=piece("FallenPlaster",Vector3(x,0.015,z)+off,Vector3(rng.randf_range(.04,.16),.018,rng.randf_range(.03,.09)),plaster)
		node.rotation.y=rng.randf_range(-PI,PI)
func aged_material(id: String,tint: Color,scale_uv: float) -> StandardMaterial3D:
	var mat:=StandardMaterial3D.new()
	mat.albedo_texture=load(LIB+id+"/Diffuse.jpg")
	mat.albedo_color=tint
	mat.roughness=1.0
	mat.metallic_specular=.08
	mat.uv1_triplanar=true
	mat.uv1_world_triplanar=true
	mat.uv1_scale=Vector3.ONE*scale_uv
	return mat
func finish_windows_and_walls():
	var glass:=aged_material("dirty_concrete",Color(.17,.23,.24),.8)
	glass.emission_enabled=true
	glass.emission=Color(.025,.033,.035)
	for body in house.get_children():
		if not body is Node3D or not body.has_node("Mesh"): continue
		var mesh: MeshInstance3D=body.get_node("Mesh")
		if not mesh.mesh is BoxMesh: continue
		var dim: Vector3=mesh.mesh.size
		if not is_equal_approx(body.position.y,1.55) or not is_equal_approx(dim.y,1.3): continue
		if not is_equal_approx(maxf(dim.x,dim.z),1.8): continue
		mesh.material_override=glass
		var along:=Vector3.RIGHT if dim.x>dim.z else Vector3.BACK
		var inward:=Vector3.ZERO
		if body.position.x<.1: inward=Vector3.RIGHT
		elif body.position.x>15.9: inward=Vector3.LEFT
		elif body.position.z<.1: inward=Vector3.BACK
		else: inward=Vector3.FORWARD
		var center: Vector3=body.position+inward*.11
		for sign in [-1,1]:
			piece("WindowJamb",center+along*.92*sign,Vector3(.075,1.43,.075),wood)
			piece("WindowRail",center+Vector3.UP*.68*sign,Vector3(1.9,.075,.075) if dim.x>dim.z else Vector3(.075,.075,1.9),wood)
		piece("WindowMullion",center,Vector3(.045,1.3,.045),wood)
		piece("WindowCrossbar",center,Vector3(1.8,.04,.04) if dim.x>dim.z else Vector3(.04,.04,1.8),wood)
		piece("DustyWindowSill",center+Vector3(0,-.68,0)+inward*.055,Vector3(1.99,.07,.25) if dim.x>dim.z else Vector3(.25,.07,1.99),wood)
func run() -> void:
	rng.seed=281029
	house=load("res://scenes/horror/house_layout.tscn").instantiate()
	house.process_mode=Node.PROCESS_MODE_DISABLED
	root.add_child(house)
	if house.has_node("GroundFloorDressing"):
		var previous=house.get_node("GroundFloorDressing")
		house.remove_child(previous)
		previous.free()
	rooms=Node3D.new()
	rooms.name="GroundFloorDressing"
	house.add_child(rooms)
	wood=load("res://assets/house_materials/floor_wood.tres")
	plaster=load("res://assets/house_materials/wall_plaster.tres") if ResourceLoader.exists("res://assets/house_materials/wall_plaster.tres") else wood
	room("LivingRoom")
	# Seating faces the television; the north doorway-to-doorway route stays open.
	p("sofa_02",10.1,15.35,2.25,180,0,true,true)
	rug(10.15,14.4,3.7,2.25)
	var coffee:=p("painted_wooden_table",10.1,14.15,0.46)
	on(coffee,"wooden_bowl_01",-.30,0,.25,15,true)
	on(coffee,"portable_cassette_player",.27,.02,.14,-12,true)
	var tvstand:=p("painted_wooden_cabinet",8.05,12.55,.84)
	on(tvstand,"Television_01",0,0,.46,30)
	p("Rockingchair_01",12.0,15.05,1.03,-135)
	var side_table:=p("painted_wooden_nightstand",12.95,15.55,.62,180)
	on(side_table,"brass_candleholders",0,0,.45,15)
	p("vintage_suitcase",7.5,15.4,.38,-15)
	p("wooden_bookshelf_worn",15.5,15.1,1.9,-90)
	var shelf: Node3D=current.get_child(current.get_child_count()-1)
	for level in [.4,.8,1.15,1.5]: on(shelf,"book_encyclopedia_set_01",-.12,0,.25,-90,false,level)
	p("hanging_picture_frame_02",12.0,15.84,.55,180,1.55,false)
	p("ornate_mirror_01",6.96,14.2,.85,90,1.45,false)
	p("metal_trash_can",7.35,12.6,.48)
	p("trashbag",7.3,13.15,.25,13,0,false)
	edge_debris(15.75,14.85,1.5,PI/2)
	room("KitchenDining")
	conceal("DiningCupboard",0)
	conceal("KitchenCupboard",0)
	# Low worktops line the north wall, away from both secret routes.
	var prep:=p("painted_wooden_cabinet",6.95,.44,.90)
	var stove:=p("electric_stove",7.85,.44,.90)
	var counter:=p("painted_wooden_cabinet",8.75,.44,.90)
	on(stove,"pot_enamel_01",-.145,.13,.16,0)
	on(counter,"vintage_electric_kettle",.16,.05,.27)
	on(prep,"wooden_cutting_board",-.12,.02,.39,0,true)
	on(prep,"wooden_spoon",.27,.04,.27,20,true)
	# Washing bowl and cleaning supplies, rather than implausible loose appliances.
	var wash:=p("painted_wooden_table",7.3,2.25,.85)
	on(wash,"wooden_bowl_01",-.4,0,.42,0,true)
	on(wash,"carved_wooden_plate",.36,.05,.28,15,true)
	p("wooden_bucket_01",6.65,2.28,.34)
	p("metal_trash_can",9.7,.50,.62)
	p("plastic_broom",11.5,.61,1.25,90,0,false)
	var pantry:=p("painted_wooden_cabinet_02",4.5,6.1,2.35,90)
	for dx in [-.20,.19]:
		for level in [1.3,1.8,2.1]: on(pantry,"russian_food_cans_01",dx,-.20,.12,90,false,level)
	var table:=p("dining_table",7.1,5.5,.77)
	p("painted_wooden_chair_01",6.55,6.55,.94,180)
	p("painted_wooden_chair_02",7.55,6.5,.98,175)
	p("painted_wooden_chair_01",6.50,4.45,.94,5)
	p("painted_wooden_chair_02",7.60,4.45,.98,-5)
	for dx in [-.48,.48]:
		for dz in [-.34,.34]: on(table,"carved_wooden_plate",dx,dz,.25,0,true)
	on(table,"wooden_bowl_01",.05,.03,.24,0,true)
	on(table,"wooden_spoon",.48,-.06,.24,8,true)
	on(counter,"wine_bottles_01",-.15,-.14,.30)
	p("hanging_picture_frame_02",8.8,7.83,.5,180,1.55,false)
	edge_debris(4.2,5.4,1.3,PI/2)
	room("Study")
	conceal("StudyCupboard",0)
	var desk:=p("painted_wooden_table",.67,3.15,.76,90)
	p("painted_wooden_chair_02",1.7,3.15,.97,-90)
	on(desk,"standing_picture_frame_01",.55,0,.24)
	on(desk,"portable_cassette_player",-.25,.10,.14,90,true)
	# Clamp attaches to the back edge, with its lower jaw below the tabletop.
	var lamp_pos:=surface(desk,-.60,-.40)
	var lamp:=p("desk_lamp_arm_01",lamp_pos.x,lamp_pos.z,.64,90,lamp_pos.y-.065,false)
	lamp.set_meta("mount","Clamp around desk edge")
	bookcase(2.3,5.58,180)
	var filing:=p("painted_wooden_cabinet",3.45,2.45,.95,-90)
	on(filing,"cardboard_box_01",0,0,.23,-10)
	p("vintage_telephone_wall_clock",3.78,5.03,.48,-90,1.3,false)
	p("metal_trash_can",.45,4.62,.45)
	p("cardboard_box_01",.45,5.5,.36,8)
	p("ornate_mirror_01",.16,1.65,.7,90,1.25,false)
	rug(2.25,3.25,1.4,1.9)
	edge_debris(.25,1.9,1.1,PI/2)
	room("UtilityRoom")
	var utility:=p("painted_wooden_table",15.4,8.3,.86,-90)
	on(utility,"wooden_bowl_01",-.40,0,.40,0,true)
	on(utility,"multi_cleaner_bottle",.45,.05,.24)
	on(utility,"multi_cleaner_bottle",.23,-.14,.21,20)
	var cupboard:=p("painted_wooden_cabinet_02",13.65,6.48,2.35)
	for level in [1.3,1.8,2.1]:
		on(cupboard,"multi_cleaner_bottle",-.18,-.20,.22,0,false,level)
		on(cupboard,"plastic_bottle_gallon",.12,-.20,.22,15,false,level)
	p("wooden_bucket_01",15.45,9.48,.36)
	p("plastic_broom",12.55,6.65,1.27,180,0,false)
	p("dustpan",12.65,6.82,.08,30,0,false)
	p("trashbag",12.55,9.42,.43)
	p("trashbag",12.95,9.56,.3,35)
	p("painted_wooden_stool",14.95,6.65,.48,20)
	p("hanging_picture_frame_02",12.17,9.05,.35,90,1.52,false)
	edge_debris(15.75,9.0,.8,PI/2)
	room("FrontStore")
	var racks:=p("wooden_bookshelf_worn",.52,13.45,2.0,90)
	for level in [.4,.8,1.2,1.6]: on(racks,"cardboard_box_01",-.15,0,.22,90,false,level)
	var crate:=p("wooden_crate_01",3.9,15.25,.65,-5)
	on(crate,"wooden_crate_02",0,0,.41,8)
	p("vintage_suitcase",1.65,15.55,.40,5)
	p("painted_wooden_bench",3.95,13.4,.85,-90)
	p("metal_toolbox",4.5,14.5,.29,15)
	p("cardboard_box_01",.55,15.4,.50)
	p("cardboard_box_01",.55,15.4,.31,10,.50)
	p("trashbag",4.65,15.6,.28,0,0,false)
	p("wooden_bucket_01",4.4,12.6,.31)
	edge_debris(2.8,15.7,1.2)
	room("HallAndLandings")
	var hallstand:=p("painted_wooden_cabinet",4.55,9.15,.90,90)
	on(hallstand,"ceramic_pot",-.2,0,.24,15)
	on(hallstand,"standing_picture_frame_01",.20,0,.23,0)
	p("ornate_mirror_01",4.17,9.1,.86,90,1.35,false)
	p("painted_wooden_bench",15.52,11.10,.88,-90)
	p("hanging_picture_frame_02",15.84,11.1,.50,-90,1.45,false)
	p("vintage_telephone_wall_clock",7.6,11.79,.52,180,1.45,false)
	p("hanging_picture_frame_02",5.36,15.2,.32,90,1.65,false)
	p("hanging_picture_frame_02",3.83,8.5,.52,-90,2.3,false)
	p("hanging_picture_frame_02",12.17,2.5,.5,90,2.35,false)
	# Narrow entrance: only wall-mounted details, nothing on the trap or bridge.
	edge_debris(7.3,11.76,.7)
	room("ArchitecturalDetails")
	finish_windows_and_walls()
	# Skirting follows real wall segments; openings and crawl entrances are omitted.
	for d in [[.15,5.8,.14],[6.6,11.8,.14],[12.2,15.8,6.14],[.2,1.2,11.85],[2.8,5.1,11.85],[7.0,9.15,11.85],[11.85,13.65,11.85],[15.15,15.8,11.85],[7.0,15.8,15.85],[.2,5.0,15.85],[4.2,4.55,7.85],[7.45,9.8,7.85],[12.2,13.2,9.85],[14.8,15.8,9.85]]:
		piece("WeatheredSkirting",Vector3((d[0]+d[1])/2,.085,d[2]),Vector3(d[1]-d[0],.17,.045),wood)
	for d in [[.15,.2,5.8],[.15,12.2,15.8],[15.85,6.2,9.8],[15.85,12.2,15.8],[6.95,12.2,15.8],[5.05,12.2,15.8],[3.85,1.9,3.15],[3.85,4.65,5.8],[12.15,6.2,7.2],[12.15,8.8,9.8]]:
		piece("WeatheredSkirting",Vector3(d[0],.085,(d[1]+d[2])/2),Vector3(.045,.17,d[2]-d[1]),wood)
	# Liners sit outside the existing door apertures, preserving full clear width.
	for d in [[2,12,1.3],[10.5,12,2.4],[14.4,12,1.2],[14,10,1.3]]:
		for side in [-1,1]: piece("SplitDoorLiner",Vector3(d[0]+side*(d[2]/2+.03),1.14,d[1]),Vector3(.06,2.28,.27),wood)
	for child in house.get_children():
		if child is Label3D and child.position.y>0 and child.position.y<3.3: child.visible=false
	for child in rooms.get_children():
		load("res://tools/house/lived_in.gd").dress(child)
		own(child,child)
		var pack:=PackedScene.new()
		assert(pack.pack(child)==OK)
		var path: String="res://scenes/horror/ground_"+str(child.name).to_snake_case()+".tscn"
		assert(ResourceSaver.save(pack,path)==OK)
		rooms.remove_child(child)
		child.free()
		var instance: Node=load(path).instantiate()
		rooms.add_child(instance)
		instance.owner=rooms
	var pack:=PackedScene.new()
	assert(pack.pack(rooms)==OK)
	assert(ResourceSaver.save(pack,"res://scenes/horror/ground_floor_dressing.tscn")==OK)
	house.remove_child(rooms)
	rooms.free()
	var instance: Node=load("res://scenes/horror/ground_floor_dressing.tscn").instantiate()
	house.add_child(instance)
	instance.owner=house
	house.process_mode=Node.PROCESS_MODE_INHERIT
	pack=PackedScene.new()
	assert(pack.pack(house)==OK)
	assert(ResourceSaver.save(pack,"res://scenes/horror/house_layout.tscn")==OK)
	FileAccess.open("res://tools/house/ground_placements.json",FileAccess.WRITE).store_string(JSON.stringify(placements,"\t"))
	print("GROUND_FLOOR_FURNISHED props=",count," room_scenes=7")
	house.free()
	quit()








