extends "res://tools/house/furnish_basement.gd"
const FLOOR=3.4
var house: Node3D
var timber: Material
var plaster_mat: Material
var metal: Material
var blood: Material
var loose_count:=0
func box(title: String,pos: Vector3,size: Vector3,mat: Material,solid:=true) -> Node3D:
	var body: Node3D=StaticBody3D.new() if solid else Node3D.new()
	body.name=title
	current.add_child(body)
	body.position=pos
	var visual=MeshInstance3D.new()
	visual.name="Mesh"
	visual.mesh=BoxMesh.new()
	visual.mesh.size=size
	visual.material_override=mat
	body.add_child(visual)
	if solid:
		var collision=CollisionShape3D.new()
		collision.name="Collision"
		collision.shape=BoxShape3D.new()
		collision.shape.size=size
		body.add_child(collision)
	return body
func u(id: String,x: float,z: float,size: float,yaw:=0.0,y:=FLOOR,solid:=true,flat:=false) -> Node3D:
	var n=prop(id,Vector3(x,y,z),size,deg_to_rad(yaw),solid,flat)
	n.set_meta("asset_id",id)
	return n
func storage(template: String,x: float,z: float,yaw:=0.0) -> Node3D:
	var n=load("res://scenes/horror/furniture/"+template+".tscn").instantiate()
	current.add_child(n)
	n.position=Vector3(x,FLOOR,z)
	n.rotation.y=deg_to_rad(yaw)
	return n
func loose(id: String,pos: Vector3,size: float,yaw:=0.0,flat:=false):
	var n=prop(id,pos,size,deg_to_rad(yaw),false,flat)
	var body=RigidBody3D.new()
	body.name=id.to_pascal_case()+"Loose"
	body.set_script(load("res://scripts/horror/loose_prop.gd"))
	body.collision_layer=1|16
	body.collision_mask=1|16
	body.mass=.6
	body.can_sleep=true
	body.linear_damp=.25
	body.angular_damp=.6
	current.add_child(body)
	body.transform=n.transform
	var model=n.get_node("Model")
	n.remove_child(model)
	body.add_child(model)
	var boxes: Array[AABB]=[]
	gather(model,Transform3D.IDENTITY,boxes)
	var bounds=boxes[0]
	for b in boxes: bounds=bounds.merge(b)
	var c=CollisionShape3D.new()
	c.shape=BoxShape3D.new()
	c.shape.size=bounds.size.max(Vector3.ONE*.025)
	c.position=bounds.get_center()
	body.add_child(c)
	current.remove_child(n)
	n.free()
	loose_count+=1
func stain(pos: Vector3,size: Vector2,wall:=false):
	var st=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var points: Array[Vector3]=[]
	for i in range(17):
		var a=TAU*i/17.0
		var r=rng.randf_range(.64,1)
		points.append(Vector3(cos(a)*size.x*r,0,sin(a)*size.y*r))
	for i in range(17):
		for p in [Vector3.ZERO,points[(i+1)%17],points[i]]: st.add_vertex(p)
	st.generate_normals()
	var m=mesh_node("DriedBlood",st.commit(),pos,blood)
	if wall: m.rotation.x=PI/2
func patch(title: String,pos: Vector3,size: Vector3,hits:=2) -> Node3D:
	var n=box(title,pos,size,plaster_mat)
	n.set_script(load("res://scripts/horror/breakable_wall.gd"))
	n.required_hits=hits
	n.fragment_material=plaster_mat
	n.add_to_group("weak_walls",true)
	# Frayed backing and laths show this is a damaged repair, rather than a solid foundation.
	for i in range(5):
		var line=box("SplitLath",pos+Vector3(0,(i-2)*.16,0),Vector3(size.x+.012,.022,size.z+.012),timber,false)
		line.rotation.z=.025*(i%2*2-1)
		line.reparent(n,true)
	return n
func wall_hole(x: float,z: float,width: float,height: float):
	# Cut an actual low opening out of an exterior X-plane wall, including its collision.
	for n in house.get_children().duplicate():
		if not n is StaticBody3D or not n.has_node("Mesh") or not n.has_node("Collision"): continue
		var c=n.get_node("Collision")
		if not c.shape is BoxShape3D: continue
		var d: Vector3=c.shape.size
		if d.x>.2 or absf(n.position.x-x)>.03: continue
		var b=AABB(n.position-d/2,d)
		if b.end.y<=FLOOR+.01 or b.position.y>=FLOOR+height or b.end.z<=z-width/2 or b.position.z>=z+width/2: continue
		var pieces: Array[AABB]=[]
		var a=maxf(b.position.z,z-width/2)
		var end=minf(b.end.z,z+width/2)
		if a>b.position.z: pieces.append(AABB(b.position,Vector3(d.x,d.y,a-b.position.z)))
		if end<b.end.z: pieces.append(AABB(Vector3(b.position.x,b.position.y,end),Vector3(d.x,d.y,b.end.z-end)))
		var top=FLOOR+height
		if b.end.y>top: pieces.append(AABB(Vector3(b.position.x,top,a),Vector3(d.x,b.end.y-top,end-a)))
		if b.position.y<FLOOR: pieces.append(AABB(Vector3(b.position.x,b.position.y,a),Vector3(d.x,FLOOR-b.position.y,end-a)))
		var material=n.get_node("Mesh").material_override
		for piece in pieces:
			var new=box("PassageWall",piece.get_center(),piece.size,material)
			new.get_node("Mesh").set_meta("house_surface","wall_wood")
		# Preserve the original nodes for recovery, but disable both their geometry and collision.
		n.get_node("Mesh").visible=false
		c.disabled=true
func tub(pos: Vector3):
	var st=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var radii=[Vector3(.83,.08,.36),Vector3(.82,.53,.35),Vector3(.72,.53,.27),Vector3(.58,.13,.17)]
	for r in range(3):
		for i in range(36):
			var a=TAU*i/36.0
			var b=TAU*(i+1)/36.0
			var p=Vector3(cos(a)*radii[r].x,radii[r].y,sin(a)*radii[r].z)
			var q=Vector3(cos(b)*radii[r].x,radii[r].y,sin(b)*radii[r].z)
			var s=Vector3(cos(a)*radii[r+1].x,radii[r+1].y,sin(a)*radii[r+1].z)
			var t=Vector3(cos(b)*radii[r+1].x,radii[r+1].y,sin(b)*radii[r+1].z)
			for v in [p,s,q,q,s,t]: st.add_vertex(v)
	st.generate_normals()
	var mesh=mesh_node("AbandonedBath",st.commit(),pos,plaster_mat)
	mesh.rotation.y=PI/2
	box("BathCollision",pos+Vector3(0,.27,0),Vector3(.72,.54,1.66),plaster_mat).get_node("Mesh").visible=false
	stain(pos+Vector3(0,.145,0),Vector2(.14,.47))
func hammer():
	var tool=RigidBody3D.new()
	tool.name="SledgehammerPickup"
	tool.set_script(load("res://scripts/horror/sledge_pickup.gd"))
	tool.freeze=true
	tool.collision_layer=1|16
	tool.collision_mask=1|16
	current.add_child(tool)
	tool.position=Vector3(7.15,-2.80,11.79)
	tool.rotation_degrees=Vector3(0,0,12)
	var visual=Node3D.new()
	visual.name="Visual"
	tool.add_child(visual)
	for data in [[Vector3(.035,.78,.035),Vector3(0,-.30,0),timber],[Vector3(.25,.125,.125),Vector3(0,.10,0),metal]]:
		var m=MeshInstance3D.new()
		m.mesh=BoxMesh.new()
		m.mesh.size=data[0]
		m.position=data[1]
		m.material_override=data[2]
		visual.add_child(m)
	var c=CollisionShape3D.new()
	c.shape=BoxShape3D.new()
	c.shape.size=Vector3(.25,.86,.13)
	c.position.y=-.26
	tool.add_child(c)
	own(tool,tool)
	var packed=PackedScene.new()
	packed.pack(tool)
	ResourceSaver.save(packed,"res://scenes/horror/sledge_pickup.tscn")
func run():
	rng.seed=281032
	house=load("res://scenes/horror/house_layout.tscn").instantiate()
	house.process_mode=Node.PROCESS_MODE_DISABLED
	root.add_child(house)
	assert(not house.has_node("UpperDressing"),"Run once on an undressed house")
	rooms=Node3D.new()
	rooms.name="UpperDressing"
	house.add_child(rooms)
	timber=load("res://assets/house_materials/floor_wood.tres")
	metal=load("res://assets/house_materials/rusted_iron.tres")
	plaster_mat=StandardMaterial3D.new()
	plaster_mat.albedo_texture=load("res://assets/house_library/damaged_plaster/Diffuse.jpg")
	plaster_mat.albedo_color=Color(.62,.61,.55)
	plaster_mat.roughness=1
	plaster_mat.uv1_triplanar=true
	plaster_mat.uv1_world_triplanar=true
	plaster_mat.uv1_scale=Vector3.ONE*.8
	plaster_mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	blood=StandardMaterial3D.new()
	blood.albedo_color=Color(.15,.012,.009)
	blood.roughness=.76
	blood.cull_mode=BaseMaterial3D.CULL_DISABLED
	room("MasterBedroom")
	u("GothicBed_01",2.3,2.1,2.1,0,FLOOR,true,true)
	u("throw_pillows_01",2.2,1.8,.7,4,FLOOR+.52,false,true)
	storage("storage_011",.95,1.8,8)
	u("alarm_clock_01",.95,1.78,.14,10,FLOOR+.63,false)
	u("vintage_cabinet_01",6.95,1.4,2.0,180)
	u("ArmChair_01",5.5,3.3,1.1,-142)
	u("painted_wooden_chair_01",3.9,4.9,.96,-31)
	storage("storage_019",1.6,5.56,180)
	u("vintage_oil_lamp",1.6,5.5,.36,0,FLOOR+.96,false)
	u("ornate_mirror_01",.16,2.0,1.0,90,FLOOR+1.2,false)
	u("hanging_picture_frame_02",2.25,.16,.6,0,FLOOR+1.5,false)
	loose("cardboard_box_01",Vector3(6.95,FLOOR+.03,3.0),.4,12)
	loose("wooden_bucket_01",Vector3(.65,FLOOR+.03,4.1),.32,-10)
	stain(Vector3(2.1,FLOOR+.012,3.0),Vector2(.62,.72))
	stain(Vector3(2.25,FLOOR+1.1,.085),Vector2(.5,.65),true)
	room("EastBedroom")
	u("vintage_day_bed",14.65,9.2,2.05,90,FLOOR,true,true)
	u("throw_pillows_01",14.6,8.9,.65,-4,FLOOR+.49,false,true)
	storage("storage_011",15.4,10.7,-90)
	u("vintage_oil_lamp",15.4,10.7,.32,0,FLOOR+.63,false)
	storage("storage_020",8.55,9.25,90)
	u("painted_wooden_table",10.4,11.38,.77,180)
	u("painted_wooden_chair_02",10.25,10.42,.99,16)
	u("boombox",10.3,11.35,.23,180,FLOOR+.78,false)
	u("hanging_picture_frame_02",15.84,8.5,.48,-90,FLOOR+1.5,false)
	loose("cardboard_box_01",Vector3(12.2,FLOOR+.02,11.1),.38,21)
	loose("wine_bottles_01",Vector3(10.85,FLOOR+.80,11.3),.27)
	stain(Vector3(14.45,FLOOR+.012,10.0),Vector2(.4,.65))
	room("SouthBedroom")
	u("old_bed_frame",11.0,14.8,2.0,90,FLOOR,true,true)
	box("RottenMattress",Vector3(11,4.0,14.8),Vector3(2,.18,.90),load("res://assets/house_materials/basement_floor.tres"))
	u("throw_pillows_01",10.4,14.8,.6,93,4.1,false,true)
	storage("storage_011",12.5,15.4,180)
	u("mantel_clock_01",12.5,15.4,.30,180,4.04,false)
	storage("storage_018",8.8,15.5,180)
	u("painted_wooden_chair_01",13.8,13.6,.95,-51)
	u("vintage_suitcase",8.6,12.8,.4,16)
	u("wooden_bookshelf_worn",15.5,15.0,2.0,-90)
	loose("cardboard_box_01",Vector3(14.5,FLOOR+.04,15.45),.42,-9)
	loose("can_rusted",Vector3(13.3,FLOOR+.05,15.35),.16)
	for i in range(8): stain(Vector3(14.8-i*.32,FLOOR+.013,12.35+i*.2),Vector2(.06,.09))
	room("Bathroom")
	tub(Vector3(11.35,FLOOR,2.55))
	storage("storage_014",8.5,2.55,90)
	u("wooden_bowl_01",8.5,2.55,.42,0,FLOOR+.91,false,true)
	u("ornate_mirror_01",8.16,2.55,.8,90,FLOOR+1.25,false)
	box("Cistern",Vector3(9.8,FLOOR+.8,.27),Vector3(.48,.46,.25),plaster_mat)
	box("ToiletPedestal",Vector3(9.8,FLOOR+.22,.60),Vector3(.28,.44,.42),plaster_mat)
	var seat=mesh_node("ToiletBowl",SphereMesh.new(),Vector3(9.8,FLOOR+.45,.67),plaster_mat)
	seat.scale=Vector3(.43,.16,.58)
	loose("bleach_bottle",Vector3(8.55,FLOOR+.93,2.3),.25,20)
	loose("wooden_bucket_01",Vector3(9.0,FLOOR+.04,3.3),.33,-17)
	u("plastic_broom",11.6,.6,1.26,17,FLOOR,false)
	stain(Vector3(11.2,FLOOR+.012,1.7),Vector2(.23,.35))
	room("UpperStore")
	storage("storage_000",2.9,15.4,-13)
	storage("storage_001",1.0,15.4,16)
	u("wooden_bookshelf_worn",.53,13.3,1.95,90)
	u("vintage_suitcase",2.0,13.5,.4,-27)
	loose("cardboard_box_01",Vector3(3.1,FLOOR+.02,13.0),.42,32)
	loose("cardboard_box_01",Vector3(3.2,FLOOR+.45,13.0),.28,-11)
	room("UpperLanding")
	u("vintage_grandfather_clock_01",6.5,7.1,2.35,180)
	u("painted_wooden_bench",11.45,9.5,.9,-87)
	u("hanging_picture_frame_02",7.84,9.4,.5,-90,FLOOR+1.5,false)
	u("painted_wooden_chair_02",6.1,10.1,.98,32)
	loose("ceramic_pot",Vector3(6.7,FLOOR+.02,9.8),.25)
	room("SecretServicePassage")
	wall_hole(0,4.9,1.05,1.05)
	wall_hole(0,14.8,1.05,1.05)
	box("ServiceFloor",Vector3(-.6,FLOOR-.08,9.9),Vector3(1.2,.16,11.0),timber)
	box("ServiceOuterWall",Vector3(-1.18,FLOOR+.55,9.9),Vector3(.12,1.1,11.1),timber)
	box("ServiceRoof",Vector3(-.6,FLOOR+1.12,9.9),Vector3(1.2,.12,11.1),timber)
	for z in [4.38,15.42]: box("ServiceEnd",Vector3(-.6,FLOOR+.55,z),Vector3(1.2,1.1,.12),timber)
	patch("WeakBedroomRepair",Vector3(-.01,FLOOR+.52,4.9),Vector3(.10,1.03,1.03))
	patch("WeakStoreRepair",Vector3(-.01,FLOOR+.52,14.8),Vector3(.10,1.03,1.03),1)
	# Existing bedroom breach is now visibly a cracked repair requiring the hammer.
	patch("WeakSouthBedroomRepair",Vector3(15.15,FLOOR+.52,12),Vector3(.96,1.03,.10))
	room("CellEscapeUpgrade")
	patch("WeakCellRepair",Vector3(4,-2.88,15.2),Vector3(.11,1.03,.94))
	hammer()
	# Make the former floating cupboard roofs read as enclosed, decayed built-ins.
	for x in [2.43,5.57]: box("CupboardBackEnclosure",Vector3(x,1.86,.75),Vector3(.07,1.42,1.2),timber)
	box("CupboardBackEnclosure",Vector3(4,2.54,.75),Vector3(3.2,.07,1.2),timber)
	# A broom closet surrounds the concealed ladder, with a real narrow doorway on its south side.
	box("LadderClosetSide",Vector3(9.91,1.35,2.95),Vector3(.10,2.7,2.2),timber)
	box("LadderClosetBack",Vector3(10.94,1.35,1.9),Vector3(2.15,2.7,.10),timber)
	box("LadderClosetFront",Vector3(10.40,1.35,4.0),Vector3(1.0,2.7,.10),timber)
	box("LadderClosetLintel",Vector3(11.42,2.45,4),Vector3(1.05,.5,.10),timber)
	box("LadderClosetTop",Vector3(10.95,2.74,2.95),Vector3(2.1,.10,2.2),timber)
	var tool=Node3D.new()
	tool.name="ToolController"
	tool.set_script(load("res://scripts/horror/tool_controller.gd"))
	house.get_node("Player").add_child(tool)
	tool.owner=house
	# Seven furnished areas and one escape/secret group stay independently editable.
	for child in rooms.get_children():
		own(child,child)
		var packed=PackedScene.new()
		packed.pack(child)
		var path="res://scenes/horror/upper_"+str(child.name).to_snake_case()+".tscn"
		ResourceSaver.save(packed,path)
		rooms.remove_child(child)
		child.free()
		var instance=load(path).instantiate()
		rooms.add_child(instance)
		instance.owner=rooms
	var packed=PackedScene.new()
	packed.pack(rooms)
	ResourceSaver.save(packed,"res://scenes/horror/upper_dressing.tscn")
	house.remove_child(rooms)
	rooms.free()
	var instance=load("res://scenes/horror/upper_dressing.tscn").instantiate()
	house.add_child(instance)
	instance.owner=house
	for n in house.get_children():
		if n is Label3D and n.position.y>3.3: n.hide()
	house.process_mode=Node.PROCESS_MODE_INHERIT
	packed=PackedScene.new()
	packed.pack(house)
	ResourceSaver.save(packed,"res://scenes/horror/house_layout.tscn")
	print("UPPER_FURNISHED props=",count," loose=",loose_count)
	house.free()
	quit()
