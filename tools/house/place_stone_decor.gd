extends SceneTree
const LIB="res://assets/house_library/"
var house: Node3D
var decor: Node3D
var records: Array=[]
var failures:=0
func _initialize() -> void: call_deferred("run")
func bounds(node: Node,t: Transform3D,boxes: Array[AABB]) -> void:
	if node is Node3D: t=t*node.transform
	if node is MeshInstance3D and node.mesh: boxes.append(t*node.get_aabb())
	for child in node.get_children(): bounds(child,t,boxes)
func merged(model: Node3D) -> AABB:
	var boxes: Array[AABB]=[]
	bounds(model,Transform3D.IDENTITY,boxes)
	var result:=boxes[0]
	for box in boxes: result=result.merge(box)
	return result
func place(scene: PackedScene,title: String,pos: Vector3,width: float,yaw: float,source: String) -> void:
	var item:=Node3D.new()
	item.name=title
	decor.add_child(item)
	item.owner=decor
	var model:=scene.instantiate() as Node3D
	model.name="Model"
	item.add_child(model)
	model.owner=decor
	model.rotation.y=deg_to_rad(yaw)
	var box:=merged(model)
	model.scale*=width/maxf(box.size.x,box.size.z)
	box=merged(model)
	model.position-=Vector3(box.get_center().x,box.position.y,box.get_center().z)
	# Ground against existing collision, within the intended surface's height band.
	var query:=PhysicsRayQueryParameters3D.create(pos+Vector3.UP*0.22,pos-Vector3.UP*0.18,1)
	query.exclude=[house.get_node("Player").get_rid()]
	var hit:=house.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		push_error("No support beneath "+title+" at "+str(pos))
		failures+=1
		return
	pos.y=hit.position.y
	item.position=pos
	item.set_meta("source",source)
	item.set_meta("dimensions_metres",box.size)
	item.set_meta("support",str(hit.collider.get_path()))
	item.set_meta("decor_only",true)
	records.append({"node":title,"position":[pos.x,pos.y,pos.z],"size":[box.size.x,box.size.y,box.size.z],"source":source})
func run() -> void:
	house=load("res://scenes/horror/house_layout.tscn").instantiate()
	root.add_child(house)
	house.set_process(false)
	house.get_node("Player").set_physics_process(false)
	if house.has_node("StoneAndWorkshopDecor"):
		var previous:=house.get_node("StoneAndWorkshopDecor")
		house.remove_child(previous)
		previous.free()
	await physics_frame
	await physics_frame
	decor=Node3D.new()
	decor.name="StoneAndWorkshopDecor"
	house.add_child(decor)
	var stone_set: Node3D=load(LIB+"rock_moss_set_01/rock_moss_set_01.gltf").instantiate()
	house.add_child(stone_set)
	var variants: Array[PackedScene]=[]
	for original in stone_set.find_children("*","MeshInstance3D",true,false):
		var rock:=Node3D.new()
		rock.name="Stone"+str(variants.size()+1)
		var visual:=MeshInstance3D.new()
		visual.name="ScannedStone"
		visual.mesh=original.mesh
		visual.transform=original.global_transform
		rock.add_child(visual)
		visual.owner=rock
		var packed:=PackedScene.new()
		packed.pack(rock)
		var path: String="res://scenes/horror/decor/stone_%02d.tscn"%(variants.size()+1)
		DirAccess.make_dir_recursive_absolute("res://scenes/horror/decor")
		ResourceSaver.save(packed,path)
		rock.free()
		variants.append(load(path))
	stone_set.free()
	var sites: Array=[
		Vector3(4.23,-3.4,13.25),Vector3(4.27,-3.4,13.55),Vector3(4.35,-3.4,13.85),
		Vector3(7.72,-3.4,15.6),Vector3(7.5,-3.4,15.72),Vector3(7.2,-3.4,15.72),
		Vector3(0.25,-3.4,5.4),Vector3(0.32,-3.4,5.1),Vector3(0.24,-3.4,4.85),
		Vector3(5.72,-3.4,1.6),Vector3(5.65,-3.4,1.85),Vector3(5.72,-3.4,2.1),
		Vector3(6.25,-3.4,1.8),Vector3(6.28,-3.4,2.15),Vector3(6.35,-3.4,2.4),
		Vector3(15.7,-3.4,9.4),Vector3(15.65,-3.4,9.7),Vector3(15.75,-3.4,10),
		Vector3(8.25,-3.4,15.5),Vector3(8.42,-3.4,15.75),Vector3(8.65,-3.4,15.8),
		Vector3(0.22,-3.4,14.2),Vector3(0.25,-3.4,14.55),Vector3(0.27,-3.4,14.85),
		Vector3(17.20,-3.4,4.1),Vector3(17.18,-3.4,7.2),Vector3(17.19,-3.4,11.1),
		Vector3(16.15,-3.4,5.7),Vector3(16.16,-3.4,9.5),Vector3(16.16,-3.4,12.7)
	]
	for i in range(sites.size()):
		var width: float=0.13+float(i%5)*0.035
		place(variants[i%variants.size()],"LooseStone_%02d"%i,sites[i],width,float(i*137%360),"https://polyhaven.com/a/rock_moss_set_01")
	var tin: PackedScene=load(LIB+"oil_tin/oil_tin.gltf")
	var can: PackedScene=load(LIB+"small_oil_can_01/small_oil_can_01.gltf")
	# Compact hand-sized containers beside work/storage areas, away from escape routes.
	for data in [[Vector3(7.45,-3.4,0.6),15],[Vector3(7.7,-3.4,0.62),-12],[Vector3(15.65,-3.4,6.55),45],[Vector3(15.35,-3.4,6.65),-25],[Vector3(11.45,-3.4,5.4),10]]:
		place(tin,"OilTin_%02d"%records.size(),data[0],0.16,float(data[1]),"https://polyhaven.com/a/oil_tin")
	place(can,"OilCanOnWorkshopTable",Vector3(13.72,-2.55,0.65),0.30,-15,"https://polyhaven.com/a/small_oil_can_01")
	place(can,"OilCanBesideBoiler",Vector3(7.4,-3.4,1.0),0.30,28,"https://polyhaven.com/a/small_oil_can_01")
	if failures>0:
		house.free()
		quit(1)
		return
	var packed:=PackedScene.new()
	packed.pack(decor)
	ResourceSaver.save(packed,"res://scenes/horror/stone_workshop_decor.tscn")
	house.remove_child(decor)
	decor.free()
	var instance: Node=load("res://scenes/horror/stone_workshop_decor.tscn").instantiate()
	house.add_child(instance)
	instance.owner=house
	house.process_mode=Node.PROCESS_MODE_INHERIT
	packed=PackedScene.new()
	packed.pack(house)
	ResourceSaver.save(packed,"res://scenes/horror/house_layout.tscn")
	var file:=FileAccess.open("res://tools/house/stone_decor_placements.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(records,"  "))
	print("DECOR_PLACED ",records.size()," pieces; ",variants.size()," stone variants")
	house.free()
	await process_frame
	quit()
