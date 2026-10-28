extends SceneTree
func _initialize(): call_deferred("run")
func support_height(shelf: Node3D,point: Vector3) -> float:
	var top=point+Vector3.UP*.08
	var best=-100.0
	for m in shelf.find_children("*","MeshInstance3D",true,false):
		if not m.visible: continue
		var faces=m.mesh.get_faces()
		for i in range(0,faces.size(),3):
			var a: Vector3=m.global_transform*faces[i]
			var b: Vector3=m.global_transform*faces[i+1]
			var c: Vector3=m.global_transform*faces[i+2]
			if absf((b-a).cross(c-a).normalized().y)<.65: continue
			var hit=Geometry3D.segment_intersects_triangle(top,top-Vector3.UP*3,a,b,c)
			if hit!=null: best=maxf(best,hit.y)
	return best
func run():
	for suffix in ["master_bedroom","east_bedroom","south_bedroom","upper_store"]:
		var path="res://scenes/horror/upper_"+suffix+".tscn"
		var room=load(path).instantiate()
		root.add_child(room)
		var shelves=[]
		for p in room.get_children():
			if p.get_meta("asset_id","")=="wooden_bookshelf_worn": shelves.append(p)
		for p in room.get_children():
			if p.get_meta("asset_id","")=="vintage_cabinet_01":
				p.position.x=7.45
				p.position.z=2.0
				p.rotation.y=-PI/2
			if p.get_meta("asset_id","") not in ["book_encyclopedia_set_01","cardboard_box_01"]: continue
			for shelf in shelves:
				if Vector2(shelf.position.x,shelf.position.z).distance_to(Vector2(p.position.x,p.position.z))>.65: continue
				var y=support_height(shelf,p.global_position)
				if y>3.4: p.global_position.y=y+.001
			if p.get_meta("asset_id","")=="vintage_cabinet_01":
				p.position.x=7.45
				p.position.z=2.0
				p.rotation.y=-PI/2
		var packed=PackedScene.new()
		packed.pack(room)
		ResourceSaver.save(packed,path)
		room.free()
	quit()

