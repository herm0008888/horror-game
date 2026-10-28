extends SceneTree
func _initialize(): call_deferred("run")
static func move_piece(room: Node3D,id: String,old: Vector2,dest: Vector2,yaw: float,carry: bool=false):
	for n in room.get_children():
		if n.get_meta("asset_id","")!=id or Vector2(n.position.x,n.position.z).distance_to(old)>.04: continue
		var before: Transform3D=n.transform
		var after:=Transform3D(Basis(Vector3.UP,deg_to_rad(yaw)),Vector3(dest.x,n.position.y,dest.y))
		if carry:
			var dim: Vector3=n.get_meta("dimensions")
			for item in room.get_children():
				if item==n or not item is Node3D or not item.has_meta("asset_id"): continue
				var local: Vector3=before.affine_inverse()*item.position
				if local.y>=dim.y-.12 and local.y<dim.y+.6 and absf(local.x)<dim.x/2 and absf(local.z)<dim.z/2:
					item.transform=after*before.affine_inverse()*item.transform
		n.transform=after
		break
static func dress(room: Node3D):
	match str(room.name):
		"KitchenDining":
			move_piece(room,"dining_table",Vector2(7.1,5.5),Vector2(7.22,5.62),-7,true)
			move_piece(room,"painted_wooden_chair_01",Vector2(6.55,6.55),Vector2(6.48,7.03),155)
			move_piece(room,"painted_wooden_chair_02",Vector2(7.55,6.5),Vector2(7.90,6.75),202)
			move_piece(room,"painted_wooden_chair_01",Vector2(6.5,4.45),Vector2(6.35,4.05),-24)
			move_piece(room,"painted_wooden_chair_02",Vector2(7.6,4.45),Vector2(8.05,4.37),18)
		"LivingRoom":
			move_piece(room,"painted_wooden_table",Vector2(10.1,14.15),Vector2(10.25,14.10),-9,true)
			move_piece(room,"Rockingchair_01",Vector2(12,15.05),Vector2(12.2,14.82),-114)
		"Study":
			move_piece(room,"painted_wooden_chair_02",Vector2(1.7,3.15),Vector2(2.03,3.10),-66)
		"UtilityRoom":
			move_piece(room,"painted_wooden_stool",Vector2(14.95,6.65),Vector2(14.7,6.9),-18)
		"FrontStore":
			move_piece(room,"painted_wooden_bench",Vector2(3.95,13.4),Vector2(3.84,13.5),-77)
			move_piece(room,"metal_toolbox",Vector2(4.5,14.5),Vector2(4.4,14.37),-12)
		"HallAndLandings":
			move_piece(room,"painted_wooden_bench",Vector2(15.52,11.1),Vector2(15.38,11.14),-83)
func run():
	for suffix in ["kitchen_dining","living_room","study","utility_room","front_store","hall_and_landings"]:
		var path="res://scenes/horror/ground_"+suffix+".tscn"
		var room=load(path).instantiate()
		dress(room)
		var pack=PackedScene.new()
		pack.pack(room)
		ResourceSaver.save(pack,path)
		room.free()
	print("LIVED_IN_LAYOUT_SAVED")
	quit()
