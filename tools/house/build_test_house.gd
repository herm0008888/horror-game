extends SceneTree
const LIB := "res://assets/house_library/"
var house := Node3D.new()
var geometry := Node3D.new()
var furniture := Node3D.new()
var lights := Node3D.new()
var interactions := Node3D.new()
var regions: Array[Dictionary] = []
var materials: Dictionary = {}
var loaded_models: Dictionary = {}
var sound_step: AudioStreamWAV
var sound_creak: AudioStreamWAV
var prop_count: int = 0
var room_centers: Dictionary = {}

func _initialize() -> void: call_deferred("build")

func mat(id: String, tint: Color = Color.WHITE, tiling: float = 0.5) -> StandardMaterial3D:
	var key := "%s_%s_%s" % [id, tint, tiling]
	if materials.has(key): return materials[key]
	var material := StandardMaterial3D.new()
	material.albedo_texture = load(LIB + id + "/Diffuse.jpg")
	material.albedo_color = tint
	material.roughness = 1.0
	material.metallic_specular = 0.12
	material.normal_enabled = true
	material.normal_texture = load(LIB + id + "/nor_gl.jpg")
	material.normal_scale = 0.55
	material.roughness_texture = load(LIB + id + "/Rough.jpg")
	material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	material.uv1_scale = Vector3.ONE * tiling
	materials[key] = material
	return material

func color_mat(color: Color, emission: bool = false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.95
	if emission:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material

func box(parent: Node, label: String, center: Vector3, size: Vector3, material: Material, solid: bool = true) -> Node3D:
	var node: Node3D = StaticBody3D.new() if solid else Node3D.new()
	node.name = label
	parent.add_child(node)
	node.position = center
	var mesh := MeshInstance3D.new()
	mesh.name = "Mesh"
	var shape := BoxMesh.new()
	shape.size = size
	shape.material = material
	mesh.mesh = shape
	node.add_child(mesh)
	if solid:
		var collider := CollisionShape3D.new()
		collider.name = "Collision"
		var physical := BoxShape3D.new()
		physical.size = size
		collider.shape = physical
		node.add_child(collider)
	return node

func gather_bounds(node: Node, transform: Transform3D, result: Array[AABB]) -> void:
	var current := transform
	if node is Node3D: current = transform * node.transform
	if node is MeshInstance3D and node.mesh: result.append(current * node.get_aabb())
	for child in node.get_children(): gather_bounds(child, current, result)

func prop(parent: Node, id: String, position: Vector3, target_size: float, angle: float = 0.0, solid: bool = true, horizontal: bool = false) -> Node3D:
	if not loaded_models.has(id): loaded_models[id] = load(LIB + id + "/" + id + ".gltf")
	var wrapper: Node3D = StaticBody3D.new() if solid else Node3D.new()
	wrapper.name = id.to_pascal_case()
	parent.add_child(wrapper)
	var model: Node3D = loaded_models[id].instantiate()
	model.name = "Model"
	wrapper.add_child(model)
	var bounds_list: Array[AABB] = []
	gather_bounds(model, Transform3D.IDENTITY, bounds_list)
	var bounds := bounds_list[0]
	for item in bounds_list: bounds = bounds.merge(item)
	var base_size := maxf(bounds.size.x, bounds.size.z) if horizontal else bounds.size.y
	var scale_factor := target_size / maxf(base_size, 0.01)
	model.scale *= scale_factor
	model.position -= Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z) * scale_factor
	if solid:
		var collision := CollisionShape3D.new()
		collision.name = "Collision"
		var shape := BoxShape3D.new()
		shape.size = bounds.size * scale_factor
		collision.shape = shape
		collision.position.y = shape.size.y * 0.5
		wrapper.add_child(collision)
	wrapper.position = position
	wrapper.rotation.y = angle
	wrapper.set_meta("source", "https://polyhaven.com/a/" + id)
	wrapper.set_meta("asset_id", id)
	wrapper.set_meta("height", bounds.size.y * scale_factor)
	prop_count += 1
	return wrapper

func lamp(label: String, position: Vector3, color: Color, energy: float = 1.0, shadows: bool = false, reach: float = 6.0) -> void:
	var light := OmniLight3D.new()
	light.name = label
	lights.add_child(light)
	light.position = position
	light.light_color = color
	light.light_energy = energy
	light.omni_range = reach
	light.omni_attenuation = 1.5
	light.shadow_enabled = shadows

func floor_rect(center: Vector3, width: float, depth: float, material: Material) -> void:
	box(geometry, "Floor", center - Vector3.UP * 0.12, Vector3(width, 0.24, depth), material)

func wall(center: Vector3, length: float, along_x: bool, material: Material, height: float = 3.2, thickness: float = 0.18) -> void:
	box(geometry, "Wall", center + Vector3.UP * height * 0.5, Vector3(length, height, thickness) if along_x else Vector3(thickness, height, length), material)

func wall_opening(center: Vector3, length: float, along_x: bool, material: Material, opening_width: float = 1.3, sill: float = 0.0, top: float = 2.42) -> void:
	var side := (length - opening_width) * 0.5
	var axis := Vector3.RIGHT if along_x else Vector3.BACK
	wall(center - axis * (opening_width + side) * 0.5, side, along_x, material)
	wall(center + axis * (opening_width + side) * 0.5, side, along_x, material)
	var size := Vector3(opening_width, 3.2 - top, 0.18) if along_x else Vector3(0.18, 3.2 - top, opening_width)
	box(geometry, "Lintel", center + Vector3.UP * (top + (3.2 - top) * 0.5), size, material)
	if sill > 0.0:
		size.y = sill
		box(geometry, "BelowWindow", center + Vector3.UP * sill * 0.5, size, material)

func door(center: Vector3, yaw: float, label: String, hatch: bool = false) -> Node3D:
	var node := Node3D.new()
	node.name = "FloorHatch" if hatch else label.to_pascal_case() + "Door"
	node.set_script(load("res://scripts/horror/test_house_door.gd"))
	node.label = label
	node.floor_hatch = hatch
	interactions.add_child(node)
	node.rotation.y = yaw
	var width := 1.23
	node.position = center - Basis(Vector3.UP, yaw).x * width * 0.5 if not hatch else center
	var hinge := Node3D.new()
	hinge.name = "Hinge"
	node.add_child(hinge)
	var wood := mat("wood_peeling_paint_weathered", Color(0.6, 0.57, 0.47), 0.65)
	if hatch:
		box(hinge, "HatchLeaf", Vector3(0, -0.055, 0.8), Vector3(1.6, 0.11, 1.6), wood)
		for x in [-0.53, 0.53]: box(hinge, "IronStrap", Vector3(x, 0.008, 0.8), Vector3(0.065, 0.025, 1.5), mat("rusty_metal_04"), false)
	else:
		box(hinge, "DoorLeaf", Vector3(width * 0.5, 1.19, 0), Vector3(width, 2.38, 0.065), wood)
		var panel_mat := mat("wood_peeling_paint_weathered", Color(0.42, 0.43, 0.35), 0.65)
		for y in [0.58, 1.72]:
			for side in [-1.0, 1.0]: box(hinge, "InsetPanel", Vector3(width * 0.5, y, side * 0.038), Vector3(width - 0.22, 0.9, 0.018), panel_mat, false)
		for side in [-1.0, 1.0]: box(hinge, "Handle", Vector3(width - 0.13, 1.05, side * 0.085), Vector3(0.14, 0.045, 0.09), mat("rusty_metal_04"), false)
	var sound := AudioStreamPlayer3D.new()
	sound.name = "Creak"
	sound.stream = sound_creak
	sound.volume_db = -21.0
	sound.max_distance = 12.0
	node.add_child(sound)
	return node

func window_at(center: Vector3, length: float, material: Material, side: int) -> void:
	wall_opening(center, length, false, material, 1.5, 1.0, 2.5)
	var trim := mat("wood_peeling_paint_weathered", Color(0.48, 0.43, 0.34), 0.7)
	for z in [-0.8, 0.8]: box(geometry, "WindowJamb", center + Vector3(0, 1.75, z), Vector3(0.24, 1.7, 0.08), trim)
	for y in [0.98, 2.52]: box(geometry, "WindowFrame", center + Vector3(0, y, 0), Vector3(0.24, 0.08, 1.7), trim)
	box(geometry, "WindowCrossbar", center + Vector3(0, 1.75, 0), Vector3(0.2, 0.045, 1.5), trim)
	box(geometry, "WindowMullion", center + Vector3(0, 1.75, 0), Vector3(0.2, 1.5, 0.045), trim)
	box(geometry, "WindowGlass", center + Vector3(float(side) * 0.025, 1.75, 0), Vector3(0.03, 1.5, 1.5), color_mat(Color(0.09, 0.14, 0.18), true))
	box(geometry, "Sill", center + Vector3(-side * 0.1, 0.97, 0), Vector3(0.5, 0.1, 1.8), trim)
	lamp("WindowGlow", center + Vector3(-side * 0.55, 2.2, 0), Color(0.43, 0.62, 0.78), 1.0, false, 6.0)

func room(label: String, side: int, floor_y: float, z_min: float, z_max: float, wall_id: String, floor_id: String) -> Node3D:
	var left: float = -8.9 if side < 0 else 1.7
	var right: float = -1.7 if side < 0 else 8.9
	var center := Vector3((left + right) * 0.5, floor_y, (z_min + z_max) * 0.5)
	var width := right - left
	var depth := z_max - z_min
	var wall_material := mat(wall_id, Color(0.78, 0.76, 0.66), 0.5)
	floor_rect(center, width, depth, mat(floor_id, Color(0.7, 0.67, 0.59), 0.38))
	wall(Vector3(center.x, floor_y, z_min + 0.045), width, true, wall_material, 3.2, 0.09)
	wall(Vector3(center.x, floor_y, z_max - 0.045), width, true, wall_material, 3.2, 0.09)
	wall_opening(Vector3(side * 1.62, floor_y, center.z), depth, false, wall_material)
	door(Vector3(side * 1.62, floor_y, center.z), -side * PI * 0.5, label)
	if floor_y < -1.0:
		wall(Vector3(side * 9.0, floor_y, center.z), depth, false, wall_material)
	else:
		window_at(Vector3(side * 9.0, floor_y, center.z), depth, wall_material, side)
	box(geometry, "RoomCeiling", center + Vector3.UP * 3.23, Vector3(width, 0.1, depth), mat("damaged_plaster", Color(0.57, 0.56, 0.48), 0.4))
	var trim := mat("wood_peeling_paint_weathered", Color(0.34, 0.31, 0.25), 0.7)
	for z in [z_min + 0.12, z_max - 0.12]: box(geometry, "Baseboard", Vector3(center.x, floor_y + 0.1, z), Vector3(width, 0.2, 0.055), trim)
	box(geometry, "OuterBaseboard", Vector3(side * 8.86, floor_y + 0.1, center.z), Vector3(0.06, 0.2, depth), trim)
	var group := Node3D.new()
	group.name = label.to_pascal_case()
	furniture.add_child(group)
	group.position = center
	regions.append({"title": label, "bounds": AABB(Vector3(left, floor_y - 0.15, z_min), Vector3(width, 3.3, depth))})
	room_centers[label] = center
	var warm := Color(1.0, 0.69, 0.4) if floor_y >= 0 else Color(0.74, 0.83, 0.65)
	lamp(label.to_pascal_case() + "Light", center + Vector3(0.4, 2.45, 0.0), warm, 1.1, label in ["Stue", "Kjøkken", "Verksted", "Soverom"], 6.5)
	prop(group, "industrial_wall_lamp", Vector3(side * 3.37, 1.95, -depth * 0.28), 0.36, PI * 0.5 if side < 0 else -PI * 0.5, false)
	return group

func stairs(base_y: float) -> void:
	var run := 7.8
	var rise := 3.4
	var width := 1.5
	var wood := mat("wood_planks_dirt", Color(0.55, 0.5, 0.39), 0.65)
	var base := Vector3(0, base_y, 0)
	for i in range(24):
		var height := float(i + 1) / 24.0 * rise
		box(geometry, "StairTread", base + Vector3(0, height - 0.065, -(i + 0.5) * run / 24.0), Vector3(width, 0.13, run / 24.0), wood, false)
	var ramp := StaticBody3D.new()
	ramp.name = "StairRamp"
	geometry.add_child(ramp)
	ramp.position = base
	var shape := ConvexPolygonShape3D.new()
	# A thin sloping slab leaves headroom beneath the stacked staircase.
	shape.points = PackedVector3Array([Vector3(-width/2,-0.14,0), Vector3(width/2,-0.14,0), Vector3(-width/2,0.02,0), Vector3(width/2,0.02,0), Vector3(-width/2,rise-0.14,-run), Vector3(width/2,rise-0.14,-run), Vector3(-width/2,rise+0.02,-run), Vector3(width/2,rise+0.02,-run)])
	var collider := CollisionShape3D.new()
	collider.shape = shape
	ramp.add_child(collider)
	for x in [-0.73, 0.73]:
		for i in range(9):
			var t := float(i) / 8.0
			box(geometry, "StairPost", base + Vector3(x, t * rise + 0.51, -t * run), Vector3(0.06, 1.0, 0.06), wood)
		var rail := box(geometry, "Handrail", base + Vector3(x, rise * 0.5 + 1.0, -run * 0.5), Vector3(0.07, 0.08, Vector2(run, rise).length()), wood)
		rail.rotation.x = atan2(rise, run)

func corridor(y: float, hatch: bool = false) -> void:
	var floor_material := mat("old_wood_floor" if y >= 0 else "concrete_floor_damaged_01", Color(0.67, 0.63, 0.53), 0.4)
	if y < 0:
		floor_rect(Vector3(0, y, 0), 3.24, 18.0, floor_material)
	else:
		floor_rect(Vector3(0, y, -8.4), 3.24, 1.2, floor_material)
		for x in [-1.22, 1.22]: floor_rect(Vector3(x, y, -3.9), 0.84, 7.8, floor_material)
		if hatch:
			floor_rect(Vector3(0, y, 2.75), 3.24, 5.5, floor_material)
			floor_rect(Vector3(0, y, 8.05), 3.24, 1.9, floor_material)
			for x in [-1.22, 1.22]: floor_rect(Vector3(x, y, 6.3), 0.84, 1.6, floor_material)
			door(Vector3(0, y, 5.5), 0, "Gulvluke", true)
		else: floor_rect(Vector3(0, y, 4.5), 3.24, 9.0, floor_material)
		var trim := mat("wood_peeling_paint_weathered", Color(0.35,0.32,0.26), 0.6)
		for x in [-0.9, 0.9]:
			box(geometry, "LandingGuardRail", Vector3(x, y+0.95, -3.9), Vector3(0.065,0.085,7.8), trim)
			for z in [-7.6,-6.2,-4.8,-3.4,-2.0,-0.4]: box(geometry, "LandingPost", Vector3(x,y+0.48,z), Vector3(0.065,0.95,0.065), trim)
	var wall_material := mat("worn_cracked_plaster", Color(0.6, 0.61, 0.52), 0.5)
	wall(Vector3(0,y,-9.0), 3.4, true, wall_material)
	if y == 0:
		wall_opening(Vector3(0,y,9.0), 3.4, true, wall_material)
		door(Vector3(0,y,9.0), 0, "Ytterdør")
	else: wall(Vector3(0,y,9.0), 3.4, true, wall_material)
	# Other levels use the underside of the actual floor, preserving the hatch opening.
	if y > 3.0: box(geometry, "HallCeiling", Vector3(0,y+3.23,4.5), Vector3(3.24,0.1,9.0), mat("damaged_plaster",Color(0.48,0.48,0.43),0.4))
	lamp("HallBulb", Vector3(0,y+2.6,4), Color(1.0,0.75,0.48), 1.0, true, 5.5)
	lamp("BackLandingBulb", Vector3(0,y+2.6,-8.3), Color(0.63,0.74,0.82), 0.7, false, 4.0)
	prop(furniture, "caged_hanging_light", Vector3(0,y+2.7,4), 1.1, 0, false, true)

func sound(kind: int) -> AudioStreamWAV:
	var sample_rate := 16000
	var duration := 0.18 if kind == 0 else (0.65 if kind == 1 else 4.0)
	var samples := int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(samples * 2)
	var random := RandomNumberGenerator.new()
	random.seed = 82 + kind
	var low: float = 0.0
	for i in range(samples):
		var t := float(i) / sample_rate
		low = lerpf(low, random.randf_range(-1.0, 1.0), 0.12)
		var amplitude: float
		if kind == 0: amplitude = (sin(t * 680.0) * 0.35 + low * 0.8) * exp(-t * 25.0) * minf(t * 300.0, 1.0)
		elif kind == 1: amplitude = (sin(t * (510.0 + sin(t * 9.0) * 80.0)) * 0.22 + low * 0.35) * sin(PI * t / duration)
		else: amplitude = low * 0.18 * (0.55 + sin(t * TAU / duration) * 0.25) * minf(t * 5.0, 1.0) * minf((duration-t)*5.0,1.0)
		data.encode_s16(i*2, int(clampf(amplitude,-1.0,1.0)*32760.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	if kind == 2:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = samples
	return stream

func make_player() -> void:
	var player := CharacterBody3D.new()
	player.name = "Player"
	player.set_script(load("res://scripts/horror/test_house_player.gd"))
	player.collision_layer = 2
	player.collision_mask = 1
	player.floor_snap_length = 0.4
	player.floor_max_angle = 0.8
	var collider := CollisionShape3D.new()
	collider.name = "Collision"
	collider.position.y = 0.85
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.25
	capsule.height = 1.7
	collider.shape = capsule
	player.add_child(collider)
	var head := Node3D.new()
	head.name = "Head"
	head.position.y = 1.65
	player.add_child(head)
	var camera := Camera3D.new()
	camera.name = "Camera"
	camera.current = true
	camera.fov = 76.0
	camera.near = 0.055
	camera.far = 50.0
	head.add_child(camera)
	var torch := SpotLight3D.new()
	torch.name = "Flashlight"
	torch.position = Vector3(0.08, -0.08, -0.04)
	torch.light_color = Color(0.9,0.87,0.7)
	torch.light_energy = 3.1
	torch.spot_range = 18.0
	torch.spot_angle = 39.0
	torch.shadow_enabled = true
	torch.visible = false
	camera.add_child(torch)
	var steps := AudioStreamPlayer3D.new()
	steps.name = "Steps"
	steps.stream = sound_step
	steps.max_distance = 12.0
	player.add_child(steps)
	player.position = Vector3(0,0.06,7.7)
	house.add_child(player)

func hud() -> void:
	var ui := CanvasLayer.new()
	ui.name = "HUD"
	house.add_child(ui)
	var location := Label.new()
	location.name = "Location"
	location.position = Vector2(16,14)
	location.add_theme_font_size_override("font_size", 13)
	location.modulate = Color(0.83,0.82,0.71)
	ui.add_child(location)
	var crosshair := Label.new()
	crosshair.name = "Crosshair"
	crosshair.text = "·"
	crosshair.position = Vector2(316,168)
	crosshair.add_theme_font_size_override("font_size", 18)
	crosshair.modulate.a = 0.5
	ui.add_child(crosshair)
	var hint := Label.new()
	hint.name = "Controls"
	hint.text = "WASD Gå  ·  E Åpne  ·  F Lys  ·  Ctrl Snik  ·  M Oversikt  ·  L Arbeidslys  ·  R Til start"
	hint.position = Vector2(14,338)
	hint.add_theme_font_size_override("font_size", 10)
	hint.modulate = Color(0.8,0.78,0.67,0.82)
	ui.add_child(hint)
	var prompt := Label.new()
	prompt.name = "Prompt"
	prompt.position = Vector2(220,292)
	prompt.add_theme_font_size_override("font_size", 14)
	ui.add_child(prompt)
	var overview := PanelContainer.new()
	overview.name = "Overview"
	overview.position = Vector2(80,50)
	overview.size = Vector2(480,250)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035,0.045,0.038,0.97)
	style.content_margin_left = 22
	style.content_margin_top = 20
	style.content_margin_right = 22
	style.content_margin_bottom = 20
	style.border_color = Color(0.4,0.43,0.32)
	style.set_border_width_all(1)
	overview.add_theme_stylebox_override("panel",style)
	ui.add_child(overview)
	var text := Label.new()
	text.text = "DET FORLATTE HUSET\n\nLOFTSETASJE\nSoverom · Gjesterom · Arbeidsværelse · Loftsbod\n\nHOVEDETASJE\nStue · Spisestue · Kjøkken · Sykestue · Vaskerom · Verksted\n\nKJELLER\nKjellerrom · Lager · Fyrrom · Redskapsrom\n\nTrappen ligger bakerst i gangen. Gulvluka er ved inngangen.\nM: lukk oversikten. L: ekstra lys for å undersøke materialer."
	text.add_theme_font_size_override("font_size",12)
	text.modulate = Color(0.86,0.85,0.73)
	overview.add_child(text)

func own(node: Node) -> void:
	for child in node.get_children():
		child.owner = house
		if child.scene_file_path.is_empty(): own(child)

func build() -> void:
	house.name = "RundownHouseTest"
	root.add_child(house)
	for pair in [[geometry,"Architecture"],[furniture,"Furniture"],[lights,"Lighting"],[interactions,"DoorsAndHatch"]]:
		var node: Node = pair[0]
		node.name = pair[1]
		house.add_child(node)
	sound_step = sound(0)
	sound_creak = sound(1)
	ResourceSaver.save(sound_step, LIB + "footstep.res")
	ResourceSaver.save(sound_creak, LIB + "door_creak.res")
	var wind := sound(2)
	ResourceSaver.save(wind, LIB + "wind.res")
	var ambience := AudioStreamPlayer.new()
	ambience.name = "HouseAmbience"
	ambience.stream = wind
	ambience.autoplay = true
	ambience.volume_db = -15.0
	house.add_child(ambience)
	for y in [-3.4,0.0,3.4]: corridor(y, y == 0.0)
	stairs(-3.4)
	stairs(0.0)
	# Ground floor: three room pairs along the central corridor.
	var living := room("Stue",-1,0,3.0,8.9,"worn_cracked_plaster","old_wood_floor")
	prop(living,"vintage_day_bed",Vector3(-2.0,0,0.5),2.1,PI*0.5,true,true)
	prop(living,"Rockingchair_01",Vector3(0.1,0,1.4),1.12,-0.55)
	prop(living,"painted_wooden_cabinet",Vector3(0.0,0,-2.3),1.45)
	prop(living,"Television_01",Vector3(0.0,1.46,-2.3),0.48,0,false)
	prop(living,"vintage_suitcase",Vector3(2.1,0,1.8),0.55,0.4)
	prop(living,"painted_wooden_table",Vector3(-0.5,0,0.1),0.48)
	prop(living,"boombox",Vector3(-0.5,0.49,0.1),0.3,0,false)
	box(living,"FadedRug",Vector3(-0.5,0.012,0.25),Vector3(3.2,0.018,2.8),mat("dirty_carpet",Color(0.55,0.5,0.39),0.8),false)
	var dining := room("Spisestue",-1,0,-3.0,3.0,"wood_peeling_paint_weathered","wood_floor_worn")
	prop(dining,"painted_wooden_cabinet_02",Vector3(-2.5,0,-2.3),1.75,0)
	prop(dining,"painted_wooden_table",Vector3(0,0,-0.1),0.75)
	for p in [Vector3(-1,0,0),Vector3(1,0,0),Vector3(0,0,1.1)]: prop(dining,"painted_wooden_chair_01",p,0.9,atan2(-p.x,-p.z))
	prop(dining,"ceramic_pot",Vector3(0,0.765,-0.1),0.28,0,false)
	prop(dining,"hanging_picture_frame_02",Vector3(0,1.7,-2.83),0.7,0,false)
	var kitchen := room("Kjøkken",-1,0,-8.9,-3.0,"long_white_tiles","dirty_tiles")
	prop(kitchen,"electric_stove",Vector3(-2.2,0,-1.7),0.87,0)
	prop(kitchen,"painted_wooden_cabinet",Vector3(-0.6,0,-2.2),0.85,0)
	prop(kitchen,"wooden_cutting_board",Vector3(-0.6,0.86,-2.15),0.45,0,false,true)
	prop(kitchen,"vintage_electric_kettle",Vector3(-2.15,0.88,-1.7),0.32,0,false)
	prop(kitchen,"russian_food_cans_01",Vector3(-0.35,0.86,-2.1),0.2,0,false)
	prop(kitchen,"wooden_bookshelf_worn",Vector3(2.2,0,-2.2),1.9,0)
	prop(kitchen,"plastic_bottle_gallon",Vector3(2.1,0,1.75),0.4,0.5)
	prop(kitchen,"metal_trash_can",Vector3(-2.75,0,1.8),0.58)
	prop(kitchen,"painted_wooden_table",Vector3(-0.2,0,0.3),0.75)
	prop(kitchen,"painted_wooden_chair_01",Vector3(0.9,0,0.4),0.9,-PI*0.5)
	prop(kitchen,"painted_wooden_stool",Vector3(-1.3,0,0.3),0.46)
	prop(kitchen,"ceramic_pot",Vector3(-0.1,0.765,0.3),0.26,0,false)
	for shelf in range(3): prop(kitchen,"russian_food_cans_01",Vector3(2.2,0.46+shelf*0.43,-2.18),0.17,0,false)
	var sick := room("Sykestue",1,0,3.0,8.9,"worn_plaster_wall","old_wood_floor")
	prop(sick,"old_bed_frame",Vector3(2.0,0,-0.4),2.05,0,true,true)
	prop(sick,"painted_wooden_nightstand",Vector3(0.8,0,-1.75),0.62)
	prop(sick,"painted_wooden_chair_02",Vector3(-1.9,0,0.6),0.9,0.6)
	prop(sick,"vintage_suitcase",Vector3(1.8,0,1.75),0.45,0.3)
	prop(sick,"painted_wooden_cabinet_02",Vector3(2.45,0,2.15),1.7,PI)
	prop(sick,"can_rusted",Vector3(2.8,0,-1.8),0.25)
	var wash := room("Vaskerom",1,0,-3.0,3.0,"long_white_tiles","worn_tile_floor")
	prop(wash,"modular_industrial_pipes_01",Vector3(2.6,0.1,-1.8),1.8,PI*0.5)
	prop(wash,"dustpan",Vector3(-1.8,0,1.75),0.42,0.2,true,true)
	prop(wash,"can_rusted",Vector3(1.8,0,1.75),0.35)
	prop(wash,"plastic_bottle_gallon",Vector3(2.4,0,1.5),0.4)
	prop(wash,"painted_wooden_cabinet_02",Vector3(-1.8,0,-2.4),1.6)
	prop(wash,"metal_trash_can",Vector3(1.0,0,-2.15),0.6)
	prop(wash,"trashbag",Vector3(0.0,0,-2.3),0.6)
	var workshop := room("Verksted",1,0,-8.9,-3.0,"damaged_plaster","concrete_floor_damaged_01")
	prop(workshop,"metal_tool_chest",Vector3(1.9,0,-1.9),0.86)
	prop(workshop,"metal_toolbox",Vector3(1.85,0.88,-1.9),0.32,0,false)
	prop(workshop,"handsaw_wood",Vector3(1.7,0.89,-1.6),0.6,0.7,false,true)
	prop(workshop,"pipe_wrench",Vector3(2.05,0.89,-1.6),0.4,0.2,false,true)
	prop(workshop,"wooden_ladder_02",Vector3(-2.4,0,-1.5),1.9,-0.2)
	prop(workshop,"utility_box_01",Vector3(3.05,1.4,0.8),0.6,-PI*0.5,false)
	# Upstairs: four larger rooms, separate material palettes.
	var bedroom := room("Soverom",-1,3.4,0.0,8.9,"worn_cracked_plaster","wood_planks_dirt")
	prop(bedroom,"vintage_day_bed",Vector3(-1.9,0,-2.5),2.05,0,true,true)
	prop(bedroom,"painted_wooden_nightstand",Vector3(-0.7,0,-3.3),0.65)
	prop(bedroom,"portable_cassette_player",Vector3(-0.7,0.66,-3.3),0.28,0,false,true)
	prop(bedroom,"painted_wooden_cabinet_02",Vector3(2.2,0,2.9),1.8,PI)
	prop(bedroom,"painted_wooden_bench",Vector3(-2.8,0,2.1),0.52,PI*0.5)
	prop(bedroom,"vintage_suitcase",Vector3(-2.7,0.54,2.1),0.34,0,false,true)
	box(bedroom,"FadedBedsideRug",Vector3(-0.2,0.012,-1.6),Vector3(2.0,0.018,3.0),mat("dirty_carpet",Color(0.6,0.55,0.43),0.8),false)
	prop(bedroom,"Rockingchair_01",Vector3(-2.6,0,1.0),1.1,0.4)
	var guest := room("Gjesterom",1,3.4,0.0,8.9,"wood_peeling_paint_weathered","dirty_carpet")
	prop(guest,"old_bed_frame",Vector3(2.0,0,-2.5),2.05,0,true,true)
	prop(guest,"painted_wooden_nightstand",Vector3(0.75,0,-3.2),0.62)
	prop(guest,"painted_wooden_chair_01",Vector3(-1.6,0,1.0),0.9,-0.7)
	prop(guest,"cardboard_box_01",Vector3(1.8,0,2.7),0.65)
	prop(guest,"boombox",Vector3(0.75,0.64,-3.2),0.38,0,false)
	var study := room("Arbeidsværelse",-1,3.4,-8.9,0.0,"worn_plaster_wall","old_wood_floor")
	prop(study,"wooden_bookshelf_worn",Vector3(-2.5,0,-3.6),2.0)
	prop(study,"painted_wooden_table",Vector3(0,0,-1.2),0.75)
	prop(study,"painted_wooden_chair_02",Vector3(0,0,0),0.9,PI)
	prop(study,"portable_cassette_player",Vector3(0,0.765,-1.2),0.3,0,false,true)
	prop(study,"hanging_picture_frame_02",Vector3(0,1.75,-4.22),0.75,0,false)
	prop(study,"painted_wooden_cabinet",Vector3(2.3,0,2.9),1.4,PI)
	prop(study,"television_02",Vector3(2.3,1.42,2.9),0.45,PI,false)
	var attic := room("Loftsbod",1,3.4,-8.9,0.0,"wood_peeling_paint_weathered","wood_planks_dirt")
	prop(attic,"wooden_ladder_02",Vector3(2.3,0,-2.6),2.0,-0.3)
	for i in range(5): prop(attic,"cardboard_box_01",Vector3(-2.0+i*0.95,0,-3.1),0.5+float(i%2)*0.2,float(i)*0.4)
	prop(attic,"old_military_crate",Vector3(2.0,0,2.8),1.0,0,true,true)
	prop(attic,"vintage_suitcase",Vector3(-2.1,0,2.8),0.55,0.6)
	for i in range(6):
		var plank := box(attic,"LooseFloorboard",Vector3(-0.7+float(i)*0.25,0.035+float(i%2)*0.025,0.3+float(i)*0.1),Vector3(0.16,0.04,1.8),mat("wood_peeling_paint_weathered",Color(0.6,0.55,0.43),0.6),false)
		plank.rotation.y = 0.25 + float(i)*0.4
	# Basement: four rooms around the stair landing.
	var cell := room("Kjellerrom",1,-3.4,0.0,8.9,"brick_wall_001","dirty_concrete")
	prop(cell,"old_bed_frame",Vector3(2.0,0,2.6),2.05,0,true,true)
	prop(cell,"can_rusted",Vector3(2.6,0,0.8),0.26)
	prop(cell,"painted_wooden_stool",Vector3(0.6,0,2.8),0.48)
	prop(cell,"plastic_bottle_gallon",Vector3(2.8,0,-2.8),0.4)
	var storage := room("Lager",-1,-3.4,0.0,8.9,"damaged_plaster","concrete_floor_damaged_01")
	for i in range(4):
		prop(storage,"wooden_crate_02",Vector3(-2.5+float(i%2)*1.5,0,-2.7+floorf(float(i)/2)*1.2),0.8,0,true,true)
	prop(storage,"wooden_barrels_01",Vector3(1.8,0,2.4),1.1)
	prop(storage,"trashbag",Vector3(-2.3,0,3.3),0.65)
	var furnace := room("Fyrrom",1,-3.4,-8.9,0.0,"cracked_concrete_wall","dirty_concrete")
	prop(furnace,"barrel_stove",Vector3(-1.6,0,-2.5),0.85)
	prop(furnace,"modular_industrial_pipes_01",Vector3(2.4,0,-2.5),2.2)
	prop(furnace,"utility_box_01",Vector3(3.15,1.2,2.0),0.7,-PI*0.5,false)
	prop(furnace,"metal_trash_can",Vector3(1.7,0,2.6),0.7)
	prop(furnace,"can_rusted",Vector3(2.6,0,2.5),0.42)
	var tools := room("Redskapsrom",-1,-3.4,-8.9,0.0,"brick_wall_001","concrete_floor_damaged_01")
	prop(tools,"metal_tool_chest",Vector3(-2.3,0,-2.8),0.95)
	prop(tools,"metal_toolbox",Vector3(-2.3,0.96,-2.8),0.32,0,false)
	prop(tools,"cross_pein_hammer",Vector3(-2.2,0.97,-2.5),0.35,0.6,false,true)
	prop(tools,"wooden_bookshelf_worn",Vector3(2.1,0,-3.5),1.9)
	prop(tools,"old_military_crate",Vector3(-2.4,0,2.9),0.9,0,true,true)
	# Hall dressing stays out of door and stair paths.
	prop(furniture,"vintage_telephone_wall_clock",Vector3(-1.46,1.7,8.2),0.48,PI*0.5,false)
	for y in [0.0,3.4]:
		for z in [1.8,8.6]: prop(furniture,"hanging_picture_frame_02",Vector3(1.48,y+1.75,z),0.55,-PI*0.5,false)
	var beam_material := mat("wooden_rough_planks",Color(0.37,0.32,0.24),0.5)
	for z in [-7.8,-4.0,0.0,4.0,7.8]: box(geometry,"AtticBeam",Vector3(0,6.45,z),Vector3(18.0,0.26,0.19),beam_material)
	# Exterior shell and shallow porch permit testing the entrance door.
	var exterior := mat("worn_plaster_wall",Color(0.43,0.45,0.38),0.4)
	for side in [-1,1]:
		for y in [0.0,3.4]: wall(Vector3(side*5.3,y,9.0),7.4,true,exterior)
		for y in [0.0,3.4]: wall(Vector3(side*5.3,y,-9.0),7.4,true,exterior)
	box(geometry,"Roof",Vector3(0,6.75,0),Vector3(18.7,0.25,18.7),mat("rusty_painted_metal",Color(0.4,0.36,0.3),0.35))
	floor_rect(Vector3(0,-0.03,10.4),4.0,2.8,mat("wood_planks_dirt"))
	for x in [-1.95,1.95]: box(geometry,"PorchRail",Vector3(x,0.5,10.4),Vector3(0.1,1.0,2.8),beam_material)
	box(geometry,"PorchEndRail",Vector3(0,0.5,11.8),Vector3(4.0,1.0,0.1),beam_material)
	lamp("PorchLight",Vector3(0,2.4,9.7),Color(0.44,0.58,0.7),0.7,false,4)
	var environment := WorldEnvironment.new()
	environment.name = "Environment"
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color(0.012,0.018,0.024)
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color(0.42,0.46,0.48)
	settings.ambient_light_energy = 0.3
	settings.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	environment.environment = settings
	house.add_child(environment)
	make_player()
	hud()
	var survey := Node3D.new()
	survey.name = "RoomMarkers"
	house.add_child(survey)
	for title in room_centers:
		var marker := Marker3D.new()
		marker.name = String(title).to_pascal_case()
		survey.add_child(marker)
		marker.position = room_centers[title]
		marker.set_meta("title",title)
	own(house)
	house.set_script(load("res://scripts/horror/test_house.gd"))
	house.room_regions = regions
	house.set_meta("prop_count",prop_count)
	house.set_meta("room_count",regions.size())
	var packed := PackedScene.new()
	var status := packed.pack(house)
	if status == OK: status = ResourceSaver.save(packed,"res://scenes/horror/rundown_house_test.tscn")
	print("TEST_HOUSE_SAVED ",status," rooms=",regions.size()," props=",prop_count," unique_models=",loaded_models.size())
	quit(0 if status == OK else 1)
