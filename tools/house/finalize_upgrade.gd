extends SceneTree
func _initialize(): call_deferred("run")
func own(n: Node,target: Node):
	for c in n.get_children(): c.owner=target; own(c,target)
func run():
	var h=load("res://scenes/horror/house_layout.tscn").instantiate()
	h.process_mode=Node.PROCESS_MODE_DISABLED
	root.add_child(h)
	h.get_node("BedroomWardrobe").rotation.y=PI
	for c in h.get_node("HUD").get_children():
		if c is Label and "LAYOUTTEST" in c.text: c.text="WASD gå · CTRL snik · E bruk · Q slipp · F lommelykt · ESC musepeker"
	# Remove the old decorative hand hammer: the usable sledge is now at the cell.
	var workshop=load("res://scenes/horror/basement_ruined_workshop.tscn").instantiate()
	for n in workshop.get_children():
		if str(n.name).begins_with("CrossPeinHammer"): n.hide()
	var pack=PackedScene.new()
	pack.pack(workshop)
	ResourceSaver.save(pack,"res://scenes/horror/basement_ruined_workshop.tscn")
	workshop.free()
	var lighting=load("res://scenes/horror/house_lighting.tscn").instantiate()
	var lights=lighting.get_node("HorrorLights")
	for data in [["UpperBathroom",Vector3(10,6.12,2),.48],["SouthBedroom",Vector3(11.2,6.10,14.3),.62],["UpperStore",Vector3(2,6.0,14),.32]]:
		var light=SpotLight3D.new()
		light.name=data[0]
		light.position=data[1]
		light.rotation_degrees.x=-90
		light.light_color=Color(.70,.64,.48)
		light.light_energy=data[2]
		light.spot_range=3.7
		light.spot_angle=52
		light.shadow_enabled=true
		light.distance_fade_enabled=true
		light.distance_fade_begin=18
		light.distance_fade_length=6
		light.distance_fade_shadow=14
		lights.add_child(light)
		light.owner=lighting
	pack=PackedScene.new()
	pack.pack(lighting)
	ResourceSaver.save(pack,"res://scenes/horror/house_lighting.tscn")
	lighting.free()
	# A model set is split into individual physical bottles, rather than a rigid row.
	var path="res://scenes/horror/upper_east_bedroom.tscn"
	var room=load(path).instantiate()
	h.add_child(room)
	for n in room.get_children().duplicate():
		if not str(n.name).begins_with("WineBottles01Loose"): continue
		var models=n.find_children("*","MeshInstance3D",true,false)
		for m in models:
			var body=RigidBody3D.new()
			body.name="LooseBottle"
			body.set_script(load("res://scripts/horror/loose_prop.gd"))
			body.mass=.45
			body.collision_layer=1|16
			body.collision_mask=1|16
			body.linear_damp=.3
			body.angular_damp=.7
			room.add_child(body)
			var bounds: AABB=m.global_transform*m.get_aabb()
			body.global_position=bounds.get_center()
			var clone=MeshInstance3D.new()
			clone.mesh=m.mesh
			clone.material_override=m.material_override
			for i in range(m.mesh.get_surface_count()): clone.set_surface_override_material(i,m.get_surface_override_material(i))
			body.add_child(clone)
			clone.global_transform=m.global_transform
			var collision=CollisionShape3D.new()
			collision.shape=BoxShape3D.new()
			collision.shape.size=bounds.size
			body.add_child(collision)
			body.owner=room
			own(body,room)
		room.remove_child(n)
		n.free()
	pack=PackedScene.new()
	pack.pack(room)
	ResourceSaver.save(pack,path)
	h.remove_child(room)
	room.free()
	pack=PackedScene.new()
	pack.pack(h)
	ResourceSaver.save(pack,"res://scenes/horror/house_layout.tscn")
	h.free()
	print("UPGRADE_FINALIZED")
	quit()
