extends SceneTree
func _initialize(): call_deferred("run")
func gather(n: Node,t: Transform3D,boxes: Array[AABB]):
	if n is Node3D: t=t*n.transform
	if n is MeshInstance3D: boxes.append(t*n.get_aabb())
	for c in n.get_children(): gather(c,t,boxes)
func run():
	for room in ["living_room","study"]:
		var path="res://scenes/horror/ground_"+room+".tscn"
		var scene=load(path).instantiate()
		for n in scene.get_children():
			var id=n.get_meta("asset_id","")
			if id not in ["portable_cassette_player","brass_candleholders"]: continue
			var model=n.get_node("Model")
			if id=="portable_cassette_player": model.rotation.x=-PI/2
			var boxes: Array[AABB]=[]
			gather(model,Transform3D.IDENTITY,boxes)
			var b=boxes[0]
			for box in boxes: b=b.merge(box)
			var factor=.14/maxf(b.size.x,b.size.z) if id=="portable_cassette_player" else .45/b.size.y
			model.scale*=factor
			model.position=(model.position-Vector3(b.get_center().x,b.position.y,b.get_center().z))*factor
			n.set_meta("dimensions",b.size*factor)
		var pack=PackedScene.new()
		pack.pack(scene)
		ResourceSaver.save(pack,path)
		scene.free()
	quit()
