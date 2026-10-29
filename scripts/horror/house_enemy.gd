extends "res://scripts/horror/house_enemy_base.gd"
@export var navigation_refresh: float=0.35
@onready var agent: NavigationAgent3D=$NavigationAgent3D
@export var catch_distance: float=1.45
@export var catch_height: float=1.1
var navigation_ready:=false
var path_stall:=0.0
var last_walkable:=Vector3.INF
var perch_time:=0.0
var escape_target:=Vector3.INF
var escape_left:=0.0
var ignoring_own_noise:=false
@export var pursuit_memory: float=25.0
@export var search_duration: float=16.0
var last_player_velocity:=Vector3.ZERO
var recovery_left:=0.0
var recovery_direction:=Vector3.ZERO
var recovery_side:=1.0
var search_target:=Vector3.ZERO
var searched_points: Array[int]=[]
func hear_noise(source: Vector3, radius: float) -> void:
	if ignoring_own_noise or caught or sees_player or global_position.distance_to(source)>radius: return
	# Quiet footsteps must not overwrite a chase or a louder investigation.
	if hunt>0 and (radius<10.0 or (has_seen_player and radius<20.0)): return
	super.hear_noise(source,radius)
	if state=="INVESTIGATE": hunt=maxf(hunt,pursuit_memory)
func begin_search() -> void:
	super.begin_search()
	search_left=search_duration
	searched_points.clear()
	search_target=last_seen
func choose_search_target() -> Vector3:
	var best:=-1
	var score:=INF
	for i in range(points.size()):
		if i in searched_points: continue
		var cost:=points[i].distance_to(last_seen)+global_position.distance_to(points[i])*.3
		if cost<score:
			best=i
			score=cost
	if best>=0:
		searched_points.append(best)
		return points[best]
	return last_seen
func steer_around_obstacle(direction: Vector3, delta: float) -> Vector3:
	recovery_left=maxf(0.0,recovery_left-delta)
	if recovery_left>0.0 and not test_move(global_transform,recovery_direction*.40):
		return recovery_direction
	if stuck_time<.12: return direction
	var collision:=KinematicCollision3D.new()
	if not test_move(global_transform,direction*.45,collision): return direction
	if collision.get_normal().y>.7: return direction
	# Keep the same passing side long enough to clear chair legs/door edges.
	for angle in [35.0,60.0,90.0,120.0]:
		for side in [recovery_side,-recovery_side]:
			var candidate:=direction.rotated(Vector3.UP,deg_to_rad(angle*side))
			if not test_move(global_transform,candidate*.50):
				recovery_direction=candidate
				recovery_side=side
				recovery_left=.85
				return candidate
	return direction
func can_see_player() -> bool:
	if not is_instance_valid(player): return false
	var to_player: Vector3=player.camera.global_position-sight_origin()
	to_player.y=0.0
	var forward: Vector3=-figure.global_basis.z
	forward.y=0.0
	# Close range must not grant vision behind her back.
	if to_player.length()>0.05 and forward.normalized().dot(to_player.normalized())<0.45: return false
	if global_position.distance_to(player.global_position)>18.0: return false
	# Sample head and torso from stable body heights. Animated head tilt must
	# not bury the only sight ray in a ceiling at a staircase.
	var space:=get_world_3d().direct_space_state
	for height in [1.65,2.15]:
		var origin: Vector3=global_position+Vector3.UP*height
		for target in [player.camera.global_position,player.global_position+Vector3.UP*.9]:
			var ray:=PhysicsRayQueryParameters3D.create(origin,target,9,[get_rid(),player.get_rid()])
			ray.collide_with_areas=true
			ray.hit_from_inside=true
			if space.intersect_ray(ray).is_empty(): return true
	return false

func should_track_player(travel: Vector3) -> bool:
	if not sees_player: return false
	var toward: Vector3=player.global_position-global_position
	toward.y=0
	if toward.length()<0.05: return false
	if travel.length()>0.1 and travel.normalized().dot(toward.normalized())<0.35: return false
	return true
func _ready() -> void:
	route=get_parent().get_node("PatrolRoutes")
	for marker in route.get_children():
		var valid:=PackedInt32Array()
		for id in marker.get_meta("links",PackedInt32Array()):
			if id>=0 and id<route.get_child_count() and id!=marker.get_index(): valid.append(id)
		marker.set_meta("links",valid)
	super._ready()
	$PathDebug.visible=false
	$PathDebug.set_process(false)
	get_tree().physics_frame.connect(_navigation_start,CONNECT_ONE_SHOT)
func _navigation_start() -> void:
	var navigation_map:=get_world_3d().navigation_map
	NavigationServer3D.map_set_cell_size(navigation_map,.08)
	NavigationServer3D.map_set_cell_height(navigation_map,.04)
	var region:=get_node_or_null("../HouseNavigation") as NavigationRegion3D
	if region and (region.navigation_mesh==null or region.navigation_mesh.get_polygon_count()==0):
		# An accidental empty scene override must not disable all movement.
		var source:=load("res://scenes/horror/house_navigation.tscn") as PackedScene
		var fallback:=source.instantiate() as NavigationRegion3D if source else null
		if fallback:
			if fallback.navigation_mesh and fallback.navigation_mesh.get_polygon_count()>0:
				region.navigation_mesh=fallback.navigation_mesh
				push_warning("Empty navigation override replaced with the saved house routes.")
			fallback.free()
			await get_tree().physics_frame
			await get_tree().physics_frame
	if region:
		NavigationServer3D.region_set_map(region.get_rid(),navigation_map)
		NavigationServer3D.region_set_navigation_mesh(region.get_rid(),region.navigation_mesh)
	NavigationServer3D.map_force_update(navigation_map)
	agent.set_navigation_map(navigation_map)
	repath=0.0
	navigation_ready=true
func _physics_process(delta: float) -> void:
	if not navigation_ready or not player or caught: return
	if NavigationServer3D.map_get_iteration_id(agent.get_navigation_map())==0: return
	sees_player=can_see_player()
	if sees_player:
		has_seen_player=true
		last_seen=player.global_position
		hunt=pursuit_memory
		last_player_velocity=player.velocity
		state="CHASE"
	else:
		if state=="CHASE":
			# Predict only once from the last observed motion; never track through walls.
			last_seen+=last_player_velocity.limit_length(3.0)*.8
			repath=0.0
		if hunt>0:
			hunt=maxf(0,hunt-delta)
			state="INVESTIGATE"
			if hunt<=0: begin_search()
		elif state=="SEARCH":
			search_left-=delta
			if search_left<=0: state="PATROL"
		else: state="PATROL"
	repath-=delta
	if repath<=0:
		repath=navigation_refresh
		var destination:=last_seen
		if state=="INVESTIGATE" and global_position.distance_to(last_seen)<0.75:
			begin_search()
		if state=="SEARCH":
			if global_position.distance_to(search_target)<1.0 or agent.is_navigation_finished():
				search_target=choose_search_target()
			destination=search_target
		elif hunt<=0 and not points.is_empty():
			if global_position.distance_to(points[patrol_index])<0.65 or agent.is_navigation_finished(): patrol_index=(patrol_index+1)%points.size()
			destination=points[patrol_index]
		agent.target_position=destination
	var next:=agent.get_next_path_position()
	route_path=agent.get_current_navigation_path()
	var direction:=Vector3(next.x-global_position.x,0,next.z-global_position.z)
	if agent.is_navigation_finished(): direction=Vector3.ZERO
	elif direction.length()>0.02: direction=direction.normalized()
	if direction.length()<.05 and hunt>0:
		path_stall+=delta
		if clear_passage(global_position,last_seen):
			direction=Vector3(last_seen.x-global_position.x,0,last_seen.z-global_position.z).normalized()
		elif path_stall>.8:
			repath=0.0
			get_tree().call_group("dynamic_navigation","request_update")
			path_stall=0.0
	else:path_stall=0.0
	# Keep stair/ramp climbing on the baked route; sidestep only on level floor.
	if direction.length()>0.1 and (not is_on_floor() or get_floor_normal().y>.98):
		direction=steer_around_obstacle(direction,delta)
	direction=recover_from_perch(direction,delta)
	var speed: float=(chase_speed if hunt>0 else patrol_speed)*motion.speed_factor(hunt>0)
	var desired:=direction*speed
	# Steer around moved/open doors. A closed storage door can be pushed open by her.
	if direction.length()>0.1:
		var ray:=PhysicsRayQueryParameters3D.create(global_position+Vector3.UP,global_position+Vector3.UP+direction*0.75,1,[get_rid(),player.get_rid()])
		var hit:=get_world_3d().direct_space_state.intersect_ray(ray)
		if not hit.is_empty():
			var node: Node=hit.collider
			while node:
				if node.has_method("set_open"):
					ignoring_own_noise=true
					node.set_open(true)
					ignoring_own_noise=false
					break
				node=node.get_parent()
	velocity.x=desired.x
	velocity.z=desired.z
	velocity.y=-0.5 if is_on_floor() else velocity.y-18*delta
	# Only step onto actual walkable routes, never climb a pot or a chair.
	if is_on_floor() and direction.length()>0.1 and test_move(global_transform,direction*0.12):
		var raised:=global_transform
		raised.origin.y+=0.23
		var landing:=raised.origin+direction*.35
		var walkable:=NavigationServer3D.map_get_closest_point(agent.get_navigation_map(),landing)
		if absf(walkable.y-landing.y)<.16 and Vector2(walkable.x-landing.x,walkable.z-landing.z).length()<.18 and not test_move(raised,direction*.35):
			global_position.y+=.23
	move_and_slide()
	var service=get_tree().get_first_node_in_group("prop_interaction")
	for i in range(get_slide_collision_count()):
		var body=get_slide_collision(i).get_collider()
		var prop: Node3D=service.resolve(body) if service else null
		if prop and service.should_highlight(prop):
			var loose: RigidBody3D=service.make_body(prop)
			if loose:
				loose.freeze=false;loose.sleeping=false
				add_collision_exception_with(loose)
				for part in service.body_colliders(loose):add_collision_exception_with(part)
				loose.apply_central_impulse(Vector3(direction.x,.1,direction.z)*.25)
		elif body is RigidBody3D and not body.freeze:body.apply_central_impulse(Vector3(direction.x,0,direction.z)*.25)
	if direction.length()>0.1 and Vector2(global_position.x-previous_position.x,global_position.z-previous_position.z).length()<delta*0.12:
		stuck_time+=delta
	else: stuck_time=0.0
	previous_position=global_position
	if stuck_time>0.8:
		repath=0.0
		recovery_side=-recovery_side
		recovery_left=0.0
		stuck_time=0.0
		get_tree().call_group("dynamic_navigation","request_update")
	if direction.length()>0.1: figure.rotation.y=lerp_angle(figure.rotation.y,atan2(-direction.x,-direction.z),delta*8)
	motion.animate(delta,direction.length()>0.1,hunt>0,figure,pose_skeleton,pose_bones,pose_rest_rotations)
	if should_track_player(direction):
		track_player_head(delta,player.camera.global_position)
		motion.apply_tracked_head(pose_skeleton,pose_bones)
		eye_gaze.track(player.camera.global_position,delta)
	else:
		relax_head_tracking(delta)
		eye_gaze.reset_gaze(delta)
	if can_catch_player() and not player.caught:
		caught=true
		player.capture(self)

func can_catch_player() -> bool:
	var offset: Vector3=player.global_position-global_position
	if Vector2(offset.x,offset.z).length()>catch_distance or absf(offset.y)>catch_height:return false
	var forward: Vector3=-figure.global_basis.z
	if Vector2(forward.x,forward.z).normalized().dot(Vector2(offset.x,offset.z).normalized())<-.1:return false
	if not sees_player and hunt<=0:return false
	for height in [.7,1.2]:
		var query:=PhysicsRayQueryParameters3D.create(global_position+Vector3.UP*height,player.global_position+Vector3.UP*height,9,[get_rid(),player.get_rid()])
		query.collide_with_areas=true;query.hit_from_inside=true
		if get_world_3d().direct_space_state.intersect_ray(query).is_empty():return true
	return false


func recover_from_perch(direction: Vector3, delta: float) -> Vector3:
	escape_left=maxf(0.0,escape_left-delta)
	if escape_left>0.0 and escape_target!=Vector3.INF:
		var toward:=escape_target-global_position
		toward.y=0
		if toward.length()>.15 and not test_move(global_transform,toward.normalized()*.25):return toward.normalized()
		escape_left=0.0
	if not is_on_floor():return direction
	var query:=PhysicsRayQueryParameters3D.create(global_position+Vector3.UP*.12,global_position-Vector3.UP*.35,1,[get_rid()])
	var hit:=get_world_3d().direct_space_state.intersect_ray(query)
	var service=get_tree().get_first_node_in_group("prop_interaction")
	var prop: Node3D=service.resolve(hit.collider) if service and not hit.is_empty() else null
	if prop==null:
		perch_time=0.0
		return direction
	perch_time+=delta
	if perch_time<.25:return direction
	# Walk off the nearest clear edge onto a lower reachable floor. No teleporting.
	var best:=INF
	for radius in [.65,1.1,1.7,2.4]:
		for i in range(16):
			var offset: Vector3=Vector3(sin(i*TAU/16.0),0,cos(i*TAU/16.0))*radius
			var start: Vector3=global_position+offset+Vector3.UP*.1
			var down:=PhysicsRayQueryParameters3D.create(start,start-Vector3.UP*2.5,1,[get_rid()])
			var floor_hit:=get_world_3d().direct_space_state.intersect_ray(down)
			if floor_hit.is_empty() or floor_hit.normal.y<.7:continue
			var landing: Vector3=floor_hit.position
			if landing.y>global_position.y-.2:continue
			if service.resolve(floor_hit.collider)!=null:continue
			if test_move(global_transform,offset):continue
			var safe:=global_transform;safe.origin=landing+Vector3.UP*.08
			if test_move(safe,Vector3.DOWN*.02):continue
			var score: float=radius+landing.distance_to(last_seen)*.12
			if score<best:best=score;escape_target=landing
	if best<INF:
		escape_left=1.8
		perch_time=0.0
		repath=0.0
		return Vector3(escape_target.x-global_position.x,0,escape_target.z-global_position.z).normalized()
	perch_time=0.0
	get_tree().call_group("dynamic_navigation","request_update")
	return direction
