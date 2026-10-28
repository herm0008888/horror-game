extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var path="res://scenes/horror/upper_east_bedroom.tscn"
	var room=load(path).instantiate()
	for n in room.get_children():
		if n is Node3D and Vector2(n.position.x,n.position.z).distance_to(Vector2(15.4,10.7))<.15:
			n.position.x=12.9
			n.position.z=9.2
	var pack=PackedScene.new()
	pack.pack(room)
	ResourceSaver.save(pack,path)
	room.free()
	# Keep the new crawl opening below the old store window free of decorative rails.
	var h=load("res://scenes/horror/house_layout.tscn").instantiate()
	var frames=h.get_node_or_null("UpperWindowFrames")
	if frames:
		for n in frames.get_children():
			if n is Node3D and n.position.x<.4 and absf(n.position.z-14)<1.2: n.visible=false
	pack=PackedScene.new()
	pack.pack(h)
	ResourceSaver.save(pack,"res://scenes/horror/house_layout.tscn")
	h.free()
	quit()
