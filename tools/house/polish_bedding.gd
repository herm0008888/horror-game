extends SceneTree
func _initialize(): call_deferred("run")
func height_at(n: Node3D,p: Vector3) -> float:
	var y=-100.0
	for m in n.find_children("*","MeshInstance3D",true,false):
		if not m.visible: continue
		var faces=m.mesh.get_faces()
		for i in range(0,faces.size(),3):
			var hit=Geometry3D.segment_intersects_triangle(p+Vector3.UP*3,p-Vector3.UP*3,m.global_transform*faces[i],m.global_transform*faces[i+1],m.global_transform*faces[i+2])
			if hit!=null: y=maxf(y,hit.y)
	return y
func run():
	for suffix in ["master_bedroom","east_bedroom","south_bedroom","bathroom"]:
		var path="res://scenes/horror/upper_"+suffix+".tscn"
		var room=load(path).instantiate()
		root.add_child(room)
		var blanket=room.get_node_or_null("StainedBlanket")
		for n in room.get_children():
			if blanket and n.get_meta("asset_id","") in ["GothicBed_01","vintage_day_bed"]:
				var y=height_at(n,blanket.global_position)
				if y>3.4: blanket.global_position.y=y+.028
			if n.name=="RottenMattress":
				var mat=StandardMaterial3D.new()
				mat.albedo_texture=load("res://assets/house_library/dirty_carpet/Diffuse.jpg")
				mat.albedo_color=Color(.56,.51,.43)
				mat.roughness=1
				n.get_node("Mesh").material_override=mat
				if blanket: blanket.position.y=4.12
		for m in room.find_children("*","MeshInstance3D",true,false):
			var old=m.material_override
			if not old is StandardMaterial3D or old.albedo_color.g>.025 or old.albedo_color.r>.18: continue
			var mat=ShaderMaterial.new()
			mat.shader=load("res://assets/house_materials/dried_blood.gdshader")
			var d: Vector3=m.get_aabb().size
			mat.set_shader_parameter("extent",Vector2(maxf(d.x/2,.01),maxf(d.z/2,.01)))
			m.material_override=mat
		var pack=PackedScene.new()
		pack.pack(room)
		ResourceSaver.save(pack,path)
		room.free()
	var e=load("res://scenes/horror/visitation.tscn").instantiate()
	var skeleton=e.find_skeleton(e.get_node("Figure"))
	for child in skeleton.get_node("RecessedSockets").get_children():
		child.mesh.radial_segments=24
		child.mesh.rings=12
	var pack=PackedScene.new()
	pack.pack(e)
	ResourceSaver.save(pack,"res://scenes/horror/visitation.tscn")
	e.free()
	quit()
