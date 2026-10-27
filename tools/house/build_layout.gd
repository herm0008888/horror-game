extends SceneTree
var house: Node3D
var materials: Array[StandardMaterial3D] = []
func _initialize() -> void:
	call_deferred("build")
func box(title: String, pos: Vector3, size: Vector3, color: int = 0, solid: bool = true) -> Node3D:
	var body: Node3D = StaticBody3D.new() if solid else Node3D.new()
	body.name = title
	house.add_child(body)
	body.position = pos
	var mesh := MeshInstance3D.new()
	mesh.name="Mesh"
	var cube := BoxMesh.new()
	cube.size = size
	mesh.mesh = cube
	mesh.material_override = materials[color % materials.size()]
	body.add_child(mesh)
	if solid:
		var collision := CollisionShape3D.new()
		collision.name="Collision"
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		body.add_child(collision)
	return body
func sign_at(title: String, pos: Vector3) -> void:
	var label := Label3D.new()
	label.text = title
	label.font_size = 32
	label.pixel_size = 0.005
	label.position = pos
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(0.85, 0.95, 1)
	house.add_child(label)
func wall(a: Vector3, b: Vector3, openings: Array, color: int) -> void:
	var length := a.distance_to(b)
	var direction := (b-a).normalized()
	var cursor := 0.0
	for opening in openings:
		var center: float = opening[0]
		var width: float = opening[1]
		var height: float = opening[2]
		segment(a + direction * cursor, direction, center-width/2-cursor, 3.2, 0, color)
		segment(a + direction * (center-width/2), direction, width, 3.2-height, height, color)
		cursor = center+width/2
	segment(a + direction*cursor, direction, length-cursor, 3.2, 0, color)
func segment(a: Vector3, dir: Vector3, length: float, height: float, bottom: float, color: int) -> void:
	if length < 0.01 or height < 0.01: return
	box("Wall", a+dir*length/2+Vector3.UP*(bottom+height/2), Vector3(length if absf(dir.x)>0.5 else 0.14,height,length if absf(dir.z)>0.5 else 0.14),color)
func flight(x: float, z: float, base_y: float, direction: float) -> void:
	var base := Vector3(x,base_y,z)
	var body := StaticBody3D.new()
	body.name = "StairFlight"
	house.add_child(body)
	body.position = base
	var shape := ConvexPolygonShape3D.new()
	var points := PackedVector3Array()
	for px in [-0.65,0.65]:
		for end in [0,1]:
			for thickness in [-0.12,0.02]:
				points.append(Vector3(px,end*1.7+thickness,direction*end*3.2))
	shape.points = points
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	for i in range(10):
		box("Tread",base+Vector3(0,(i+1)*0.17-0.06,direction*(i+0.5)*0.32),Vector3(1.3,0.12,0.32),5,false)
	for side in [-1,1]:
		for i in range(6):
			box("RailPost",base+Vector3(side*0.72,i*1.7/5+0.48,direction*i*3.2/5),Vector3(0.05,0.96,0.05),5)
		var rail := box("Handrail",base+Vector3(side*0.72,1.81,direction*1.6),Vector3(0.07,0.07,sqrt(3.2*3.2+1.7*1.7)),5)
		rail.rotation.x = -direction*atan2(1.7,3.2)
func u_stair(left: float, north: float, mirrored: bool, base_y: float = 0.0) -> void:
	flight(left+(3.05 if mirrored else 0.95),north+4.2,base_y,-1)
	box("TurningLanding",Vector3(left+2,base_y+1.6,north+0.5),Vector3(4,0.2,1),5)
	flight(left+(0.95 if mirrored else 3.05),north+1,base_y+1.7,1)
	# Guard the top opening, leaving only the ascending flight and landing accessible.
	var guard_x: float = left+(3.05 if mirrored else 0.95)
	if base_y>=0:
		box("LandingGuard",Vector3(guard_x,base_y+3.9,north+4.17),Vector3(2.0,1,0.1),5)
func slab(x1: float,z1: float,x2: float,z2: float,y: float,color: int) -> void:
	box("Floor",Vector3((x1+x2)/2,y-0.1,(z1+z2)/2),Vector3(x2-x1,0.2,z2-z1),color)
	for x in range(int(ceil(x1)),int(x2)+1):
		box("Grid",Vector3(x,y+0.005,(z1+z2)/2),Vector3(0.012,0.008,z2-z1),6,false)
	for z in range(int(ceil(z1)),int(z2)+1):
		box("Grid",Vector3((x1+x2)/2,y+0.005,z),Vector3(x2-x1,0.008,0.012),6,false)
func line(x1: float,z1: float,x2: float,z2: float,y: float,gaps: Array = [],color: int = 0) -> void:
	wall(Vector3(x1,y,z1),Vector3(x2,y,z2),gaps,color)
func window_wall(a: Vector3,b: Vector3,centers: Array) -> void:
	var direction := (b-a).normalized()
	var cursor := 0.0
	for center in centers:
		var width := 1.8
		segment(a+direction*cursor,direction,center-width/2-cursor,3.2,0,0)
		segment(a+direction*(center-width/2),direction,width,0.9,0,0)
		segment(a+direction*(center-width/2),direction,width,1.0,2.2,0)
		var pane := box("WindowPlaceholder",a+direction*center+Vector3.UP*1.55,Vector3(width if absf(direction.x)>0.5 else 0.08,1.3,width if absf(direction.z)>0.5 else 0.08),4)
		var blue := StandardMaterial3D.new()
		blue.albedo_color=Color("63899b")
		blue.emission_enabled=true
		blue.emission=Color("344c5c")
		pane.get_child(0).material_override=blue
		cursor=center+width/2
	segment(a+direction*cursor,direction,a.distance_to(b)-cursor,3.2,0,0)
func cut_ground_floor() -> void:
	var holes := [Rect2(0,6,4,4.2),Rect2(5.2,13.2,1.6,1.6),Rect2(10,2,1.2,1.2)]
	var xs: Array[float] = [0,4,5.2,6.8,10,11.2,16]
	var zs: Array[float] = [0,2,3.2,6,10.2,13.2,14.8,16]
	for xi in range(xs.size()-1):
		for zi in range(zs.size()-1):
			var midpoint := Vector2((xs[xi]+xs[xi+1])/2,(zs[zi]+zs[zi+1])/2)
			var empty := false
			for hole in holes:
				if hole.has_point(midpoint): empty=true
			if not empty: slab(xs[xi],zs[zi],xs[xi+1],zs[zi+1],0,1)
func basement() -> void:
	slab(0,0,16,16,-3.4,0)
	line(0,0,16,0,-3.4)
	line(0,0,0,16,-3.4)
	line(0,16,16,16,-3.4)
	line(16,0,16,16,-3.4,[[2.8,0.95,1.05],[14.2,0.95,1.05]])
	line(0,6,4,6,-3.4)
	line(4,6,4,12,-3.4,[[5,1.5,2.5]])
	line(0,12,4,12,-3.4,[[2,1.3,2.3]])
	line(6,0,6,6,-3.4,[[3.5,1.3,2.3]])
	line(4,6,12,6,-3.4,[[1,1.3,2.3],[5,1.3,2.3]])
	line(12,0,12,12,-3.4,[[3,1.3,2.3],[8.5,1.3,2.3]])
	line(8,12,16,12,-3.4,[[5,1.3,2.3]])
	# Cell below the entrance. Its gate stays locked; the low corner breach is the exit.
	line(4,12,4,16,-3.4,[[3.2,0.95,1.05]])
	line(8,12,8,16,-3.4)
	for i in range(19):
		box("CellBar",Vector3(4.1+i*0.21,-1.85,12),Vector3(0.055,3.1,0.055),5)
	for height in [-3.2,-1.9,-0.4]:
		box("CellCrossbar",Vector3(6,height,12),Vector3(4,0.08,0.08),5)
	box("LockedGateFrame",Vector3(5.4,-1.85,12),Vector3(0.09,3.1,0.1),5)
	box("LockedGateFrame",Vector3(6.6,-1.85,12),Vector3(0.09,3.1,0.1),5)
	box("GateLock",Vector3(6.5,-2.0,12.08),Vector3(0.22,0.24,0.13),2)
	box("BrokenBrick",Vector3(4.1,-3.25,14.52),Vector3(0.4,0.3,0.3),2)
	box("BrokenBrick",Vector3(3.8,-3.28,15.88),Vector3(0.34,0.24,0.25),2)
	u_stair(0,6,false,-3.4)
	# Low foundation tunnel links two separated cellar rooms, with entrances at opposite ends.
	slab(16,2,17.4,15,-3.4,0)
	box("TunnelRoof",Vector3(16.7,-2.2,8.5),Vector3(1.4,0.2,13),2)
	box("TunnelOuterWall",Vector3(17.4,-2.8,8.5),Vector3(0.14,1.2,13),0)
	box("TunnelEnd",Vector3(16.7,-2.8,2),Vector3(1.4,1.2,0.14),0)
	box("TunnelEnd",Vector3(16.7,-2.8,15),Vector3(1.4,1.2,0.14),0)
	for z in [3,5,7,9,11,13]:
		for x in [16.12,17.28]:
			box("TunnelSupport",Vector3(x,-2.85,z),Vector3(0.04,1.1,0.06),5,false)
		box("TunnelSupport",Vector3(16.7,-2.29,z),Vector3(1.2,0.06,0.06),5,false)
	# A second way upstairs: a ladder behind the kitchen cupboard, through a real floor opening.
	for x in [10.3,10.9]:
		box("LadderRail",Vector3(x,-1.55,2.95),Vector3(0.06,3.7,0.06),5)
	for i in range(12):
		box("LadderRung",Vector3(10.6,-3.1+i*0.3,2.95),Vector3(0.65,0.045,0.06),5,false)
	box("LadderCover",Vector3(10.6,-0.08,2.6),Vector3(1.2,0.16,1.2),5)
	box("KitchenCupboard",Vector3(10.3,1.2,3.6),Vector3(1.3,2.4,0.5),3)
	# Hinged trapdoor aligns with the cell below. The panel is a distinct movable body.
	var hinge := Node3D.new()
	hinge.name="EntranceHatch"
	hinge.position=Vector3(6,0,13.2)
	house.add_child(hinge)
	var panel := box("Panel",Vector3(6,-0.08,14),Vector3(1.6,0.16,1.6),5)
	panel.reparent(hinge,true)
	panel.get_child(1).name="Collision"
	for data in [["INNSPERRET",6,14],["KJELLER",8,9],["VERKSTED",14,6],["FYRROM",9,4],["LAGER",3,3],["BOD",12,14]]:
		sign_at(data[0],Vector3(data[1],-0.95,data[2]))
	for pos in [Vector3(16.7,-2.55,3),Vector3(16.7,-2.55,8),Vector3(16.7,-2.55,14)]:
		var light := OmniLight3D.new()
		light.position=pos
		light.omni_range=5
		light.light_energy=0.4
		house.add_child(light)
func own(node: Node) -> void:
	for child in node.get_children():
		child.owner = house
		own(child)
func build() -> void:
	for color in [Color("687789"),Color("7b8875"),Color("9c8576"),Color("77718e"),Color("718b8b"),Color("c4a56e"),Color("26323d")]:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.roughness = 1
		materials.append(mat)
	house = Node3D.new()
	house.name = "HouseLayout"
	root.add_child(house)
	# The upper slab has two compact stair openings, rather than long slots through halls.
	cut_ground_floor()
	slab(4,0,12,16,3.4,2)
	slab(0,0,4,6,3.4,3)
	slab(0,10.2,4,16,3.4,3)
	slab(12,4.2,16,16,3.4,3)
	box("Roof",Vector3(8,6.7,8),Vector3(16,0.16,16),0)
	for y in [0.0,3.4]:
		window_wall(Vector3(0,y,0),Vector3(16,y,0),[2.0,6.0,10.0])
		window_wall(Vector3(0,y,0),Vector3(0,y,16),[3.0,14.0])
		window_wall(Vector3(16,y,0),Vector3(16,y,16),[8.5,13.5])
		if y>0:
			window_wall(Vector3(0,y,16),Vector3(16,y,16),[2.0,10.0,14.0])
		else:
			window_wall(Vector3(8,y,16),Vector3(16,y,16),[2.0,6.0])
			line(0,16,8,16,y,[[6,1.2,2.3]])
			box("FrontDoorPlaceholder",Vector3(6,1.15,16),Vector3(1.2,2.3,0.12),5)
	# Domestic ground floor. The two main rooms have stepped perimeters, not a cell grid.
	line(4,0,4,6,0,[[0.75,1.0,1.05],[3.9,1.3,2.3]],2) # Study to eat-in kitchen.
	line(0,6,4,6,0,[],2)
	line(4,6,4,12,0,[[5,1.5,2.5]],2)
	# A single front-room wall serves storage, the entrance passage and the living room.
	# The passage walls are shared room boundaries all the way to the outside wall.
	line(0,12,16,12,0,[[2,1.3,2.3],[6,1.6,2.5],[10.5,2.4,2.5],[14.4,1.2,2.3]],2)
	line(5.2,12,5.2,16,0,[],2)
	line(6.8,12,6.8,16,0,[],2)
	# Kitchen/dining room is one generous L, with two everyday exits forming a loop.
	line(4,8,10,8,0,[[2.0,2.6,2.6]],1)
	line(10,6,10,8,0,[],1)
	line(10,6,12,6,0,[[1,1.3,2.3]],1)
	line(12,0,12,6,0,[[5.1,1.35,2.4]],2)
	line(12,6,16,6,0,[],2)
	# Utility room is the only small, enclosed service room downstairs.
	line(12,6,12,10,0,[[2,1.3,2.3]],2)
	line(12,10,16,10,0,[[2,1.3,2.3]],2)
	# Upstairs: an ordinary bent landing serving three bedrooms and a bathroom.
	line(4,6,4,12,3.4,[[5,1.5,2.5]],2)
	# Main bedroom has a recessed entrance/dressing corner, rather than four flat sides.
	line(0,6,6,6,3.4,[[5,1.2,2.3]],3)
	line(6,4,6,6,3.4,[],3)
	line(6,4,8,4,3.4,[],3)
	line(8,0,8,4,3.4,[],3)
	# Bathroom remains enclosed, accessible only from the short back landing.
	line(8,4,12,4,3.4,[[2,0.95,2.2]],4)
	line(12,0,12,6,3.4,[[5.1,1.35,2.4]],2)
	# Second bedroom takes the former oversized common space and has an L-shaped outline.
	line(8,7,12,7,3.4,[[2,1.2,2.3]],3)
	line(12,6,12,7,3.4,[],3)
	line(12,6,16,6,3.4,[],3)
	line(8,7,8,12,3.4,[],3)
	# South bedroom has a deep entrance recess; storage is an adjoining domestic cupboard room.
	line(0,12,4,12,3.4,[],2)
	line(4,12,6,12,3.4,[],3)
	line(6,12,6,14,3.4,[],3)
	line(6,14,8,14,3.4,[[1,1.1,2.3]],3)
	line(8,12,8,14,3.4,[],3)
	line(8,12,16,12,3.4,[[7.15,1.0,1.05]],3)
	line(4,12,4,16,3.4,[[3,1.1,2.3]],3)
	u_stair(0,6,false)
	u_stair(12,0,true)
	for data in [
		["ENTRÉ",6,15,0],["BOD",2.5,14,0],["STUE",11,14,0],["KJØKKEN / SPISEPLASS",8,4.8,0],
		["KONTOR",2,3,0],["VASKEROM",14,8,0],
		["SOVEROM",3,3,3.4],["BAD",10,2,3.4],
		["SOVEROM",12,9,3.4],["SOVEROM",11,14,3.4],["BOD",2,14,3.4]
	]:
		sign_at(data[0],Vector3(data[1],data[3]+2.5,data[2]))
	# Cupboard backs hide a low passage through the study/kitchen party wall.
	box("SecretPassageRoof",Vector3(4,1.12,0.75),Vector3(3.2,0.14,1.2),5)
	box("StudyCupboard",Vector3(3.15,1.2,1.55),Vector3(1.3,2.4,0.5),3)
	box("DiningCupboard",Vector3(4.85,1.2,1.55),Vector3(1.3,2.4,0.5),3)
	# Upper bedroom escape: a corner breach concealed by a wardrobe, linking separate bedrooms.
	box("BedroomWardrobe",Vector3(14,4.6,11.1),Vector3(2,2.4,0.65),3)
	box("BrokenPlaster",Vector3(14.45,3.55,12.08),Vector3(0.25,0.3,0.3),2)
	box("BridgePlank",Vector3(9,0,10),Vector3(1.0,0.08,2.8),5)
	basement()
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("242d38")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 0.75
	environment.environment = env
	house.add_child(environment)
	for level in [-1,0,1]:
		for x in [2,6,10,14]:
			for z in [2,6,10,14]:
				var light := OmniLight3D.new()
				light.position = Vector3(x,level*3.4+2.8,z)
				light.omni_range = 5
				light.light_energy = 0.45
				house.add_child(light)
	var player := CharacterBody3D.new()
	player.name = "Player"
	player.position = Vector3(6,0.1,14)
	player.floor_max_angle = deg_to_rad(48)
	player.floor_snap_length = 0.3
	player.set_script(load("res://scripts/horror/layout_player.gd"))
	var collision := CollisionShape3D.new()
	collision.name = "Collision"
	var shape := CapsuleShape3D.new()
	shape.height = 1.7
	shape.radius = 0.25
	collision.shape = shape
	collision.position.y = 0.86
	player.add_child(collision)
	var camera := Camera3D.new()
	camera.name = "Camera"
	camera.position.y = 1.6
	camera.fov = 80
	camera.current = true
	camera.near = 0.05
	player.add_child(camera)
	house.add_child(player)
	var hud := CanvasLayer.new()
	hud.name="HUD"
	var hint := Label.new()
	hint.text = "HUS / LAYOUTTEST · WASD gå · CTRL snik · E stige · R tilbake · T prøv fallet\nKjeller + to etasjer · testflater · ESC musepeker"
	hint.position = Vector2(12,10)
	hint.add_theme_font_size_override("font_size",13)
	hud.add_child(hint)
	house.add_child(hud)
	var status := Label.new()
	status.name="Status"
	status.position=Vector2(12,52)
	status.add_theme_font_size_override("font_size",13)
	hud.add_child(status)
	house.set_script(load("res://scripts/horror/basement_runtime.gd"))
	own(house)
	var packed := PackedScene.new()
	packed.pack(house)
	var error := ResourceSaver.save(packed,"res://scenes/horror/house_layout.tscn")
	print("LAYOUT_BUILD ",error)
	quit(error)
