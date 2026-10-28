extends "res://scripts/horror/house_enemy_base.gd"
@export var navigation_refresh: float=0.35
@onready var agent: NavigationAgent3D=$NavigationAgent3D
var navigation_ready:=false
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
	navigation_ready=true
func _physics_process(delta: float) -> void:
	if not navigation_ready or not player or caught: return
	if NavigationServer3D.map_get_iteration_id(agent.get_navigation_map())==0: return
	sees_player=can_see_player()
	if sees_player:
		has_seen_player=true
		last_seen=player.global_position
		hunt=10.0
		state="CHASE"
	else:
		hunt=maxf(0,hunt-delta)
		state="INVESTIGATE" if hunt>0 else "PATROL"
	repath-=delta
	if repath<=0:
		repath=navigation_refresh
		var destination:=last_seen
		if hunt<=0 and not points.is_empty():
			if global_position.distance_to(points[patrol_index])<0.65 or agent.is_navigation_finished(): patrol_index=(patrol_index+1)%points.size()
			destination=points[patrol_index]
		agent.target_position=destination
	var next:=agent.get_next_path_position()
	route_path=agent.get_current_navigation_path()
	var direction:=Vector3(next.x-global_position.x,0,next.z-global_position.z)
	if agent.is_navigation_finished(): direction=Vector3.ZERO
	elif direction.length()>0.02: direction=direction.normalized()
	var speed: float=(chase_speed if hunt>0 else patrol_speed)*motion.speed_factor(hunt>0)
	var desired:=direction*speed
	# Steer around moved/open doors. A closed storage door can be pushed open by her.
	if direction.length()>0.1:
		var ray:=PhysicsRayQueryParameters3D.create(global_position+Vector3.UP,global_position+Vector3.UP+direction*0.75,1,[get_rid(),player.get_rid()])
		var hit:=get_world_3d().direct_space_state.intersect_ray(ray)
		if not hit.is_empty() and hit.collider.has_method("set_open"): hit.collider.set_open(true)
	velocity.x=desired.x
	velocity.z=desired.z
	velocity.y=-0.5 if is_on_floor() else velocity.y-18*delta
	if is_on_floor() and direction.length()>0.1 and test_move(global_transform,direction*0.12):
		var raised:=global_transform
		raised.origin.y+=0.23
		if not test_move(raised,direction*0.16): global_position.y+=0.23
	move_and_slide()
	if direction.length()>0.1 and global_position.distance_to(previous_position)<delta*0.08:
		stuck_time+=delta
	else: stuck_time=0.0
	previous_position=global_position
	if stuck_time>0.8:
		repath=0.0
		agent.target_position=agent.target_position
		stuck_time=0.0
	if direction.length()>0.1: figure.rotation.y=lerp_angle(figure.rotation.y,atan2(-direction.x,-direction.z),delta*8)
	motion.animate(delta,direction.length()>0.1,hunt>0,figure,pose_skeleton,pose_bones,pose_rest_rotations)
	if has_seen_player:
		track_player_head(delta,attention_target())
		motion.apply_tracked_head(pose_skeleton,pose_bones)
		eye_gaze.track(attention_target(),delta)
	if global_position.distance_to(player.global_position)<0.95 and sees_player and not player.caught:
		caught=true
		player.capture(self)
