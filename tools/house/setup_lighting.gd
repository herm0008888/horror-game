extends SceneTree
func _initialize() -> void: call_deferred("run")
func own(node: Node, owner_node: Node) -> void:
	for child in node.get_children():
		child.owner=owner_node
		own(child,owner_node)
func run() -> void:
	var house := load("res://scenes/horror/house_layout.tscn").instantiate() as Node3D
	house.process_mode=Node.PROCESS_MODE_DISABLED
	root.add_child(house)
	if house.has_node("Lighting"):
		var previous := house.get_node("Lighting")
		house.remove_child(previous)
		previous.free()
	var world: WorldEnvironment
	for node in house.get_children():
		if node is WorldEnvironment: world=node
	world.name="Environment"
	var normal := load("res://assets/house_materials/normal_lighting.tres") as Environment if ResourceLoader.exists("res://assets/house_materials/normal_lighting.tres") else world.environment.duplicate() as Environment
	ResourceSaver.save(normal,"res://assets/house_materials/normal_lighting.tres")
	var horror := normal.duplicate() as Environment
	horror.background_color=Color(0.003,0.004,0.007)
	horror.ambient_light_color=Color(0.72,0.75,0.80)
	horror.ambient_light_energy=0.36
	ResourceSaver.save(horror,"res://assets/house_materials/horror_lighting.tres")
	normal=load("res://assets/house_materials/normal_lighting.tres")
	horror=load("res://assets/house_materials/horror_lighting.tres")
	var rig := Node3D.new()
	rig.name="Lighting"
	var lights := Node3D.new()
	lights.name="HorrorLights"
	rig.add_child(lights)
	house.add_child(rig)
	var lamps := [
		["EntranceLamp",Vector3(6,2.65,13),2.0],
		["HallLamp",Vector3(6,2.65,6.2),2.4],
		["KitchenLamp",Vector3(10.4,2.65,3.5),1.9],
		["StudyLamp",Vector3(2,2.65,2.4),1.7],
		["LivingLamp",Vector3(13,2.65,13.0),1.7],
		["UpperLandingLamp",Vector3(6,6.05,8),2.1],
		["WestBedroomLamp",Vector3(2,6.05,3),1.7],
		["EastBedroomLamp",Vector3(14,6.05,8.5),1.7],
		["CellLamp",Vector3(6,-0.7,14),1.7],
		["BasementHallLamp",Vector3(9,-0.7,8),1.9],
		["BasementStoreLamp",Vector3(2,-0.7,3),1.5],
		["BasementEastLamp",Vector3(14,-0.7,14),1.4]
	]
	for data in lamps:
		var light := SpotLight3D.new()
		light.name=data[0]
		light.position=data[1]
		light.rotation_degrees.x=-90
		light.light_color=Color(0.83,0.74,0.56) if light.position.y>0 else Color(0.70,0.76,0.59)
		light.light_energy=data[2]*0.16
		light.spot_range=3.8
		light.spot_angle=38
		light.spot_attenuation=1.35
		light.spot_angle_attenuation=0.8
		light.shadow_enabled=true
		light.shadow_bias=0.1
		light.set_meta("base_energy",data[2]*0.16)
		lights.add_child(light)
	for data in [
		["ColdWindowGround",Vector3(.18,2.0,3),Vector3(4,0.7,3)],
		["ColdWindowUpper",Vector3(.18,5.4,14),Vector3(4,4.1,14)],
		["StairSpill",Vector3(1.0,2.4,9.5),Vector3(2.5,0.4,7)]
	]:
		var light := SpotLight3D.new()
		light.name=data[0]
		lights.add_child(light)
		light.look_at_from_position(data[1],data[2])
		light.light_color=Color(.35,.50,.74)
		light.light_energy=.136
		light.spot_range=5.8
		light.spot_angle=40
		light.shadow_enabled=true
	own(rig,rig)
	rig.set_script(load("res://scripts/horror/house_lighting.gd"))
	rig.environment_node=NodePath("../"+str(world.name))
	rig.horror_environment=horror
	rig.normal_environment=normal
	var packed_rig := PackedScene.new()
	packed_rig.pack(rig)
	ResourceSaver.save(packed_rig,"res://scenes/horror/house_lighting.tscn")
	house.remove_child(rig)
	rig.free()
	var saved_rig := load("res://scenes/horror/house_lighting.tscn").instantiate() as Node3D
	house.add_child(saved_rig)
	saved_rig.owner=house
	saved_rig.scene_file_path="res://scenes/horror/house_lighting.tscn"
	world.environment=horror
	for node in house.get_children():
		if node is OmniLight3D: node.visible=false
	house.process_mode=Node.PROCESS_MODE_INHERIT
	var packed := PackedScene.new()
	packed.pack(house)
	var error := ResourceSaver.save(packed,"res://scenes/horror/house_layout.tscn")
	print("HOUSE_LIGHTING_SAVED ",error)
	quit(error)
