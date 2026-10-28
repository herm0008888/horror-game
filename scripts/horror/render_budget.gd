extends Node
## Keep the interface native; cap only the expensive 3D image on larger displays.
const MAX_3D_SIZE:=Vector2(1600,1000)
const MIN_3D_SIZE:=Vector2(1152,720)
var max_scale:=1.0
var min_scale:=1.0
var warmup:=2.0
var sample_ms:=15.0
var slow_time:=0.0
var fast_time:=0.0
var light_timer:=0.0
var last_view_position:=Vector3.INF
var last_view_forward:=Vector3.ZERO
var last_view_fov:=-1.0
func _ready():
	add_to_group("render_budget")
	get_viewport().mesh_lod_threshold=2.0
	get_viewport().size_changed.connect(update_resolution)
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(),true)
	update_resolution()
	call_deferred("limit_small_shadows")
func limit_small_shadows():
	# Tiny ornaments still render, but do not submit additional shadow geometry.
	for mesh in get_parent().find_children("*","MeshInstance3D",true,false):
		if not mesh.is_inside_tree() or mesh.mesh==null or mesh.skin!=null:continue
		var size=mesh.get_aabb().size*mesh.global_basis.get_scale().abs()
		if size.length()<.45:
			mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
func update_resolution():
	var viewport=get_viewport()
	var size=viewport.get_visible_rect().size
	if size.x<=0 or size.y<=0:return
	max_scale=minf(1.0,minf(MAX_3D_SIZE.x/size.x,MAX_3D_SIZE.y/size.y))
	min_scale=minf(max_scale,minf(MIN_3D_SIZE.x/size.x,MIN_3D_SIZE.y/size.y))
	viewport.scaling_3d_scale=max_scale
	warmup=2.0
func _physics_process(delta):
	light_timer-=delta
	if light_timer<=0:
		light_timer=.18
		update_light_visibility()
func _process(delta):
	if delta<=0 or delta>.1:return
	if warmup>0:
		warmup-=delta
		return
	var viewport=get_viewport()
	var gpu_ms=RenderingServer.viewport_get_measured_render_time_gpu(viewport.get_viewport_rid())
	var ms=gpu_ms if gpu_ms>.01 else delta*1000.0
	sample_ms=lerpf(sample_ms,ms,1.0-exp(-delta*3.0))
	slow_time=slow_time+delta if sample_ms>(15.7 if gpu_ms>.01 else 17.6) else 0.0
	fast_time=fast_time+delta if sample_ms<(12.0 if gpu_ms>.01 else 14.0) else 0.0
	if slow_time>.65 and viewport.scaling_3d_scale>min_scale+.001:
		viewport.scaling_3d_scale=maxf(min_scale,viewport.scaling_3d_scale-.05)
		slow_time=0;fast_time=0
	elif fast_time>4.0 and viewport.scaling_3d_scale<max_scale-.001:
		viewport.scaling_3d_scale=minf(max_scale,viewport.scaling_3d_scale+.025)
		slow_time=0;fast_time=0
func structure_blocks(start: Vector3,finish: Vector3,excluded: Array[RID]) -> bool:
	var space=get_parent().get_world_3d().direct_space_state
	for i in range(8):
		var query=PhysicsRayQueryParameters3D.create(start,finish,1,excluded)
		var hit=space.intersect_ray(query)
		if hit.is_empty():return false
		if start.distance_to(hit.position)>=start.distance_to(finish)-.12:return false
		var mesh=hit.collider.get_node_or_null("Mesh") as MeshInstance3D
		if (mesh and mesh.has_meta("house_surface")) or hit.collider.is_in_group("weak_walls"):return true
		excluded.append(hit.collider.get_rid())
	return false
func update_light_visibility():
	var house=get_parent()
	var manager=house.get_node_or_null("HouseVisibility")
	var camera=get_viewport().get_camera_3d()
	if manager==null or camera==null:return
	var forward=-camera.global_basis.z
	if camera.global_position.distance_squared_to(last_view_position)<.04 and forward.distance_squared_to(last_view_forward)<.0025 and is_equal_approx(camera.fov,last_view_fov):return
	last_view_position=camera.global_position
	last_view_forward=forward
	last_view_fov=camera.fov
	manager.refresh(camera)
	var floors=manager.visible_floors(camera.global_position,camera)
	var excluded: Array[RID]=[]
	var player=house.get_node_or_null("Player")
	if player is CollisionObject3D:excluded.append(player.get_rid())
	for data in manager.lights:
		var light=data.node
		if data.work or not light is SpotLight3D:continue
		if data.floor not in floors:
			light.visible=false
			continue
		var floor_y=float(data.floor)*3.4
		var center=Vector3(light.global_position.x,floor_y+.5,light.global_position.z)
		var samples=[light.global_position,center,center+Vector3.UP,center+Vector3(2.4,0,0),center-Vector3(2.4,0,0),center+Vector3(0,0,2.4),center-Vector3(0,0,2.4)]
		var visible=false
		for point in samples:
			if camera.is_position_in_frustum(point) and not structure_blocks(camera.global_position,point,excluded.duplicate()):
				visible=true;break
		light.visible=visible

func invalidate_visibility():
	last_view_position=Vector3.INF
	light_timer=0.0
