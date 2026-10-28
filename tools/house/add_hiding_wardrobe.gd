extends SceneTree
func _initialize(): call_deferred("run")
func own(n: Node,target: Node):
	for c in n.get_children(): c.owner=target; own(c,target)
func deepen(n: Node,ratio: float):
	for c in n.get_children():
		if c is Node3D: c.position.z*=ratio
		if c is MeshInstance3D and c.mesh is BoxMesh:
			c.mesh=c.mesh.duplicate()
			c.mesh.size.z*=ratio
		if c is CollisionShape3D and c.shape is BoxShape3D:
			c.shape=c.shape.duplicate()
			c.shape.size.z*=ratio
		deepen(c,ratio)
func run():
	var path="res://scenes/horror/furniture/bedroom_wardrobe.tscn"
	var cabinet=load(path).instantiate()
	deepen(cabinet,.88/.65)
	var pack=PackedScene.new()
	pack.pack(cabinet)
	ResourceSaver.save(pack,path)
	cabinet.free()
	var master_path="res://scenes/horror/upper_master_bedroom.tscn"
	var south_path="res://scenes/horror/upper_south_bedroom.tscn"
	var master=load(master_path).instantiate()
	var south=load(south_path).instantiate()
	for n in master.get_children().duplicate():
		if n.get_meta("asset_id","")!="vintage_cabinet_01": continue
		master.remove_child(n)
		south.add_child(n)
		n.position=Vector3(5.2,3.4,12.6)
		n.rotation.y=0
		n.owner=south
		own(n,south)
	var hiding=load(path).instantiate()
	hiding.name="MasterHidingWardrobe"
	master.add_child(hiding)
	hiding.position=Vector3(6.9,4.6,.65)
	hiding.rotation=Vector3.ZERO
	hiding.owner=master
	pack=PackedScene.new()
	pack.pack(master)
	ResourceSaver.save(pack,master_path)
	pack=PackedScene.new()
	pack.pack(south)
	ResourceSaver.save(pack,south_path)
	master.free()
	south.free()
	quit()
