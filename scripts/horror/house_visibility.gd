extends Node
## Conservative floor portals complement mesh occluders. Physics and AI always stay active.
var house: Node3D
var groups: Array[Dictionary]=[]
var lights: Array[Dictionary]=[]
var timer:=0.0
var last_key:=""
var enabled:=true
func _ready():
	house=get_parent()
	get_tree().root.use_occlusion_culling=true
	for data in [["GroundFloorDressing",0],["BasementDressing",-1],["StoneWorkshopDecor",-1],["UpperWindowFrames",1]]:
		var n=house.get_node_or_null(data[0])
		if n: groups.append({"node":n,"floor":data[1]})
	var upper=house.get_node_or_null("UpperDressing")
	if upper:
		for n in upper.get_children():
			if n.name!="CellEscapeUpgrade": groups.append({"node":n,"floor":1})
	var rig=house.get_node_or_null("Lighting")
	if rig:
		rig.mode_changed.connect(func(_normal): last_key=""; timer=0)
		for n in rig.get_node("HorrorLights").get_children():
			if n is Light3D: lights.append({"node":n,"floor":clampi(floori((n.global_position.y+.3)/3.4),-1,1),"work":false})
	for n in house.get_children():
		if n is OmniLight3D: lights.append({"node":n,"floor":clampi(floori((n.global_position.y+.3)/3.4),-1,1),"work":true})
	refresh(get_viewport().get_camera_3d(),true)
func portal_in_view(camera: Camera3D,level: int,back: bool) -> bool:
	if not camera: return true
	for height in [.35,1.25,2.3]:
		for offset in [-.65,0.0,.65]:
			var point=Vector3(12,level*3.4+height,5.1+offset*.6) if back else Vector3(4,level*3.4+height,11+offset)
			if camera.is_position_in_frustum(point): return true
	return false
func visible_floors(point: Vector3,camera: Camera3D=null) -> Array:
	var level=-1 if point.y<.35 else (1 if point.y>3.75 else 0)
	var floors: Array=[level]
	var p=Vector2(point.x,point.z)
	if Rect2(-1,5,6,8).has_point(p):
		for other in [-1,0,1]:
			if other!=level and portal_in_view(camera,other,false): floors.append(other)
	if level>=0 and Rect2(11,-1,6,8).has_point(p):
		var other=1-level
		if other not in floors and portal_in_view(camera,other,true): floors.append(other)
	return floors
func refresh(camera: Camera3D,force:=false):
	if not camera: return
	var floors: Array=visible_floors(camera.global_position,camera) if enabled else [-1,0,1]
	var normal: bool=house.get_node("Lighting").normal_lighting
	var key=str(floors)+str(normal)
	if not force and key==last_key: return
	last_key=key
	var geometry_floors: Array=floors.duplicate()
	var point=Vector2(camera.global_position.x,camera.global_position.z)
	if Rect2(-1,5,6,8).has_point(point): geometry_floors=[-1,0,1]
	elif camera.global_position.y>=.35 and Rect2(11,-1,6,8).has_point(point): geometry_floors=[0,1]
	for g in groups: g.node.visible=g.floor in geometry_floors
	for light in lights: light.node.visible=(light.floor in floors) and (normal if light.work else true)
func _process(delta):
	timer-=delta
	if timer>0: return
	timer=.08
	refresh(get_viewport().get_camera_3d())



