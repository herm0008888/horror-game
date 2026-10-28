extends "res://tools/house/build_upper_upgrade.gd"
func flatten(n: Node):
	n.scene_file_path=""
	for c in n.get_children(): flatten(c)
func cloth(pos: Vector3,size: Vector2,angle: float):
	var st=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for x in range(18):
		for z in range(20):
			for corner in [Vector2i(0,0),Vector2i(0,1),Vector2i(1,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,1)]:
				var uv=Vector2((x+corner.x)/18.0,(z+corner.y)/20.0)
				st.set_uv(uv*2)
				st.add_vertex(Vector3((uv.x-.5)*size.x,sin(uv.x*41+uv.y*4)*.013+sin(uv.y*18)*.008,(uv.y-.5)*size.y))
	st.generate_normals()
	var mat=StandardMaterial3D.new()
	mat.albedo_texture=load(LIB+"dirty_carpet/Diffuse.jpg")
	mat.albedo_color=Color(.44,.40,.30)
	mat.roughness=1
	var m=mesh_node("StainedBlanket",st.commit(),pos,mat)
	m.rotation.y=deg_to_rad(angle)
func run():
	rng.seed=281034
	house=load("res://scenes/horror/house_layout.tscn").instantiate()
	house.process_mode=Node.PROCESS_MODE_DISABLED
	root.add_child(house)
	timber=load("res://assets/house_materials/floor_wood.tres")
	plaster_mat=load("res://assets/house_materials/wall_wood.tres")
	metal=load("res://assets/house_materials/rusted_iron.tres")
	var glass=StandardMaterial3D.new()
	glass.albedo_texture=load(LIB+"dirty_concrete/Diffuse.jpg")
	glass.albedo_color=Color(.16,.21,.22)
	glass.roughness=1
	glass.uv1_triplanar=true
	var architectural=Node3D.new()
	architectural.name="UpperWindowFrames"
	house.add_child(architectural)
	current=architectural
	for body in house.get_children():
		if not body is Node3D or not body.has_node("Mesh"): continue
		var m=body.get_node("Mesh")
		if str(body.name)=="Roof": m.material_override=timber
		if not m.mesh is BoxMesh or not is_equal_approx(body.position.y,4.95) or not is_equal_approx(m.mesh.size.y,1.3): continue
		if not is_equal_approx(maxf(m.mesh.size.x,m.mesh.size.z),1.8): continue
		m.material_override=glass
		var along=Vector3.RIGHT if m.mesh.size.x>m.mesh.size.z else Vector3.BACK
		var inward=Vector3.RIGHT if body.position.x<.1 else (Vector3.LEFT if body.position.x>15.9 else (Vector3.BACK if body.position.z<.1 else Vector3.FORWARD))
		var center: Vector3=body.position+inward*.11
		for side in [-1,1]:
			box("WindowJamb",center+along*.92*side,Vector3(.065,1.4,.065),timber,false)
			box("WindowRail",center+Vector3.UP*.68*side,Vector3(1.9,.065,.065) if along.x else Vector3(.065,.065,1.9),timber,false)
		box("Mullion",center,Vector3(.04,1.3,.04),timber,false)
		box("Crossbar",center,Vector3(1.8,.04,.04) if along.x else Vector3(.04,.04,1.8),timber,false)
		box("Sill",center+Vector3(0,-.67,0),Vector3(1.96,.08,.28) if along.x else Vector3(.28,.08,1.96),timber,false)
	own(architectural,house)
	architectural.owner=house
	# The old purple block becomes a panelled wooden wardrobe with working doors.
	var wardrobe=load("res://scenes/horror/furniture/bedroom_wardrobe.tscn").instantiate()
	var worn=StandardMaterial3D.new()
	worn.albedo_texture=load(LIB+"wood_peeling_paint_weathered/Diffuse.jpg")
	worn.albedo_color=Color(.48,.42,.34)
	worn.roughness=1
	worn.uv1_triplanar=true
	worn.uv1_scale=Vector3.ONE*.65
	for m in wardrobe.find_children("*","MeshInstance3D",true,false): m.material_override=worn
	for door in [wardrobe.get_node("LeftDoor"),wardrobe.get_node("RightDoor")]:
		if door.get_child_count()>3: continue
		var panel=door.get_node("Panel")
		for x in [-.43,.43]:
			var trim=MeshInstance3D.new()
			trim.mesh=BoxMesh.new()
			trim.mesh.size=Vector3(.055,2.18,.035)
			trim.material_override=timber
			door.add_child(trim)
			trim.position=panel.position+Vector3(x,0,.035)
			trim.owner=wardrobe
		var handle=MeshInstance3D.new()
		handle.mesh=BoxMesh.new()
		handle.mesh.size=Vector3(.025,.14,.04)
		handle.material_override=metal
		door.add_child(handle)
		handle.position=panel.position+Vector3(.32 if door.name=="LeftDoor" else -.32,.02,.065)
		handle.owner=wardrobe
	var pack=PackedScene.new()
	pack.pack(wardrobe)
	ResourceSaver.save(pack,"res://scenes/horror/furniture/bedroom_wardrobe.tscn")
	wardrobe.free()
	for suffix in ["master_bedroom","east_bedroom","south_bedroom","bathroom","upper_store","upper_landing"]:
		var path="res://scenes/horror/upper_"+suffix+".tscn"
		var scene=load(path).instantiate()
		house.add_child(scene)
		current=scene
		if scene.has_node("StainedBlanket"):
			house.remove_child(scene)
			scene.free()
			continue
		var before=scene.get_children()
		for n in before.duplicate():
			if n.has_meta("asset_id") and n.get_meta("asset_id")=="throw_pillows_01":
				before.erase(n)
				scene.remove_child(n)
				n.free()
		for m in scene.find_children("DriedBlood*","MeshInstance3D",true,false):
			var mat=ShaderMaterial.new()
			mat.shader=load("res://assets/house_materials/dried_blood.gdshader")
			var d: Vector3=m.get_aabb().size
			mat.set_shader_parameter("extent",Vector2(maxf(d.x/2,.01),maxf(d.z/2,.01)))
			m.material_override=mat
		match suffix:
			"master_bedroom":
				for n in before.duplicate():
					if n.has_meta("asset_id") and n.get_meta("asset_id")=="hanging_picture_frame_02": n.position.x=4.15
					if n.has_meta("asset_id") and n.get_meta("asset_id")=="ornate_mirror_01": n.position.z=1.2
				cloth(Vector3(2.3,4.05,2.25),Vector2(1.2,1.5),-3)
				u("wooden_bookshelf_worn",6.9,5.55,2.0,180)
				for i in range(4): u("book_encyclopedia_set_01",6.9,5.54,.26,180,FLOOR+.37+i*.37,false)
				for x in [1.25,1.65]: u("standing_picture_frame_01",x,5.48,.23,90,FLOOR+.96,false)
				u("wooden_bowl_01",3.25,2.9,.24,0,FLOOR,false,true)
				loose("vintage_suitcase",Vector3(5.5,FLOOR+.03,.6),.36,-9)
				for z in [.6,.95]: loose("cardboard_box_01",Vector3(6.2,FLOOR+.04,z),.27,22)
			"east_bedroom":
				for n in before.duplicate():
					if n.has_meta("asset_id") and n.get_meta("asset_id")=="hanging_picture_frame_02": n.position.z=10.5
				cloth(Vector3(14.65,3.94,9.2),Vector2(1.5,.65),-2)
				u("hanging_picture_frame_02",10.6,11.84,.5,180,FLOOR+1.45,false)
				u("book_encyclopedia_set_01",10.55,11.4,.25,180,FLOOR+.78,false)
				u("wooden_bookshelf_worn",12.2,7.5,1.95)
				for i in range(4): u("book_encyclopedia_set_01",12.2,7.5,.25,0,FLOOR+.35+i*.35,false)
				loose("metal_toolbox",Vector3(12.0,FLOOR+.03,10.9),.25,16)
			"south_bedroom":
				cloth(Vector3(11,4.10,14.8),Vector2(1.8,.82),4)
				for i in range(4): u("book_encyclopedia_set_01",15.5,15.0,.25,-90,FLOOR+.36+i*.36,false)
				u("hanging_picture_frame_02",12.0,15.84,.6,180,FLOOR+1.6,false)
				for i in range(3): loose("can_rusted",Vector3(13.2+i*.2,FLOOR+.04,15.3),.14,16*i)
			"bathroom":
				var porcelain=StandardMaterial3D.new()
				porcelain.albedo_texture=load(LIB+"dirty_concrete/Diffuse.jpg")
				porcelain.albedo_color=Color(.72,.70,.63)
				porcelain.roughness=.86
				for n in before.duplicate():
					if n.name in ["Cistern","ToiletPedestal"]: n.get_node("Mesh").material_override=porcelain
					if n.name in ["AbandonedBath","ToiletBowl"]: n.material_override=porcelain
				for i in range(3): loose("multi_cleaner_bottle",Vector3(8.45,FLOOR+.92,2.65+i*.10),.21,35*i)
				u("hanging_picture_frame_02",11.83,1.8,.34,-90,FLOOR+1.4,false)
			"upper_store":
				for i in range(4): u("cardboard_box_01",.52,13.3,.20,90,FLOOR+.37+i*.36,false)
				u("plastic_broom",3.5,12.6,1.2,15,FLOOR,false)
				u("dustpan",3.3,12.8,.09,-25,FLOOR,false)
			"upper_landing":
				storage("storage_010",7.4,11.5,180)
				u("brass_candleholders",7.4,11.5,.4,180,FLOOR+.85,false)
				u("hanging_picture_frame_02",9.8,6.84,.45,180,FLOOR+1.4,false)
		# Own new additions only; existing interactive scene instances retain their hinge data.
		for n in scene.get_children():
			if n not in before:
				if n.scene_file_path.contains("/furniture/"): n.owner=scene
				else:
					flatten(n)
					n.owner=scene
					own(n,scene)
		pack=PackedScene.new()
		pack.pack(scene)
		ResourceSaver.save(pack,path)
		house.remove_child(scene)
		scene.free()
	pack=PackedScene.new()
	pack.pack(house)
	ResourceSaver.save(pack,"res://scenes/horror/house_layout.tscn")
	house.free()
	print("UPPER_FINISHED new_props=",count," extra_loose=",loose_count)
	quit()


