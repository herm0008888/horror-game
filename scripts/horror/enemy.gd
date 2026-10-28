extends CharacterBody3D
@export var player: CharacterBody3D
@export var wander_radius: float = 5.0
@export var patrol_speed: float = 1.15
@export var chase_speed: float = 2.65
@onready var figure: Node3D = $Figure
@onready var motion: Node = $HauntedMotion
@onready var corner: Node = $CornerStalker
@onready var eye_gaze: Node = $EyeGaze
@onready var breath: AudioStreamPlayer3D = $Breath
var route_path := PackedVector3Array()
var repath: float = 0
var hunt: float = 0
var gait: float = 0
var waiting_door: Node3D
var has_seen_player := false
var sees_player := false
var caught := false
var state: String = "PATROL"
var search_left: float = 0.0
var search_origin := Vector3.ZERO
var search_step: int = 0
var previous_position := Vector3.ZERO
var stuck_time: float = 0.0
var avoidance_side: float = 1.0
var steering_left: float = 0.0
var steering_direction := Vector3.ZERO
var wander_goal_left: float = 0.0
var escape_left: float = 0.0
var escape_direction := Vector3.ZERO
var head: Node3D
var arm_left: Node3D
var arm_right: Node3D
var last_seen := Vector3.ZERO
var pose_skeleton: Skeleton3D
var pose_bones: Dictionary = {}
var pose_rest_rotations: Dictionary = {}

func find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D: return node
	for child in node.get_children():
		var found := find_skeleton(child)
		if found: return found
	return null

func _exit_tree() -> void:
	breath.stop()

func _ready() -> void:
	add_to_group("horror_listener")
	previous_position = global_position
	avoidance_side = -1.0 if randf() < 0.5 else 1.0
	head = figure.find_child("HeadPivot", true, false)
	arm_left = figure.find_child("ArmLeft", true, false)
	arm_right = figure.find_child("ArmRight", true, false)
	pose_skeleton = find_skeleton(figure)
	if pose_skeleton:
		for bone in ["Head", "Spine", "ArmLeft", "ArmRight", "ForearmLeft", "ForearmRight", "LegLeft", "LegRight", "EyeLeft", "EyeRight", "Tongue"]:
			var index := pose_skeleton.find_bone(bone)
			if index >= 0:
				pose_bones[bone] = index
				pose_rest_rotations[bone] = pose_skeleton.get_bone_pose_rotation(index)
	breath.play()

func _physics_process(delta: float) -> void:
	if not player or caught: return
	var offset := player.global_position - global_position
	var distance := offset.length()
	var same_floor := absf(offset.y) < 2.0
	var previously_visible := sees_player
	sees_player = can_see_player()
	var visible_player := sees_player
	if visible_player:
		has_seen_player = true
		if state != "CHASE": route_path.clear()
		state = "CHASE"
		hunt = 7.0
		last_seen = player.global_position
	else:
		if previously_visible:
			# Discard the live chase endpoint as soon as sight is broken.
			state = "INVESTIGATE"
			route_path.clear()
			repath = 0.0
	if not visible_player and hunt > 0:
		hunt = maxf(0, hunt - delta)
		if hunt <= 0: begin_search()
	if state == "SEARCH":
		search_left -= delta
		if search_left <= 0:
			state = "PATROL"
			has_seen_player = false
			route_path.clear()
	corner.tick(delta, visible_player)
	wander_goal_left -= delta
	if state in ["PATROL", "SEARCH"] and wander_goal_left <= 0.0 and not corner.active:
		route_path.clear()
		repath = 0.0
		wander_goal_left = randf_range(2.5, 4.5)
	repath -= delta
	if repath <= 0 and (route_path.is_empty() or (state == "CHASE" and visible_player)):
		repath = 0.55
		var destination := global_position
		if state in ["CHASE", "INVESTIGATE"]:
			destination = last_seen
			if global_position.distance_to(last_seen) < 0.85 and not visible_player and not corner.active:
				begin_search()
				destination = random_walk_target()
		else:
			destination = random_walk_target()
		if corner.active: destination = corner.destination
		route_path = plan_route(destination)
	if state == "CHASE" and visible_player and not corner.active and clear_passage(global_position,player.global_position):
		route_path = PackedVector3Array([player.global_position])
	while route_path.size() > 1 and clear_passage(global_position,route_path[1]): route_path.remove_at(0)
	var direction := Vector3.ZERO
	if route_path.size() > 0:
		var target := route_path[0]
		var flat := target - global_position
		flat.y = 0
		if flat.length() < 0.13: route_path.remove_at(0)
		else: direction = flat.normalized()
	if direction.length() > 0.1:
		var hit := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(global_position + Vector3.UP, global_position + Vector3.UP + direction * 1.3, 1, [get_rid(),player.get_rid()]))
		if not hit.is_empty():
			var node: Node = hit.collider
			while node:
				if node.has_method("set_open"):
					node.set_open(true)
					waiting_door = node
					break
				node = node.get_parent()
	if is_instance_valid(waiting_door):
		if waiting_door.can_pass(): waiting_door = null
		else: direction = Vector3.ZERO
	steering_left -= delta
	escape_left = maxf(0.0, escape_left - delta)
	var intentionally_waiting: bool = corner.holding or is_instance_valid(waiting_door)
	var wants_to_move: bool = direction.length_squared() > 0.01 and not intentionally_waiting
	if intentionally_waiting:
		direction = Vector3.ZERO
	elif wants_to_move:
		if escape_left > 0.0: direction = escape_direction
		if steering_left <= 0.0:
			steering_direction = steer_around_obstacles(direction)
			steering_left = 0.16
		direction = steering_direction
	var speed: float = (chase_speed if hunt > 0 else patrol_speed) * motion.speed_factor(hunt > 0) * corner.speed_factor()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if not is_on_floor(): velocity.y -= delta * 18
	else: velocity.y = -0.5
	move_and_slide()
	if wants_to_move and global_position.distance_to(previous_position) < delta * 0.15:
		stuck_time += delta
	else: stuck_time = 0.0
	previous_position = global_position
	if stuck_time > 0.65:
		avoidance_side *= -1.0
		var away := -steering_direction
		if away.length_squared() < 0.01: away = figure.global_basis.z
		away.y = 0.0
		escape_direction = steer_around_obstacles(away.normalized())
		escape_left = 1.2
		steering_left = 0.0
		route_path.clear()
		repath = 0.0
		stuck_time = 0.0
	if direction.length() > 0.1 and not corner.holding:
		figure.rotation.y = lerp_angle(figure.rotation.y, atan2(-direction.x, -direction.z), delta * 8)
	if corner.holding:
		figure.position = Vector3.ZERO
		figure.rotation.z = 0.0
	else:
		motion.animate(delta, direction.length() > 0.1, hunt > 0, figure, pose_skeleton, pose_bones, pose_rest_rotations)
	corner.pose_lean(pose_skeleton, pose_bones)
	if has_seen_player or state in ["INVESTIGATE", "SEARCH"]:
		var focus := attention_target()
		track_player_head(delta, focus)
		if corner.holding:
			corner.pose_head(pose_skeleton, pose_bones)
		else:
			motion.apply_tracked_head(pose_skeleton, pose_bones)
		eye_gaze.track(focus,delta)
	breath.pitch_scale = 0.84 + (0.16 if hunt > 0 else 0)
	if distance < 1.05 and same_floor and visible_player and not player.caught:
		caught = true
		player.capture(self)

func hear_noise(source: Vector3, radius: float) -> void:
	if caught or sees_player: return
	if global_position.distance_to(source) > radius: return
	last_seen = source
	state = "INVESTIGATE"
	hunt = 12.0
	route_path.clear()
	repath = 0.0
	# A sound is a clue at its source, not permission to track its owner.
	corner.active = false
	corner.holding = false

func begin_search() -> void:
	state = "SEARCH"
	hunt = 0.0
	search_left = 9.0
	search_origin = last_seen
	search_step = 0
	route_path.clear()
	repath = 0.0

func clear_passage(start: Vector3, finish: Vector3) -> bool:
	if absf(start.y - finish.y) > 0.65: return false
	var side := (finish - start).cross(Vector3.UP).normalized() * 0.285
	for offset in [Vector3.ZERO, side, -side]:
		for height in [0.35, 1.3]:
			var lift: Vector3 = Vector3.UP * height
			var query := PhysicsRayQueryParameters3D.create(start + lift + offset, finish + lift + offset, 1, [get_rid(), player.get_rid()])
			if not get_world_3d().direct_space_state.intersect_ray(query).is_empty(): return false
	return true

func sight_origin() -> Vector3:
	if pose_skeleton and pose_bones.has("EyeLeft") and pose_bones.has("EyeRight"):
		var left := pose_skeleton.get_bone_global_pose(pose_bones["EyeLeft"]).origin
		var right := pose_skeleton.get_bone_global_pose(pose_bones["EyeRight"]).origin
		return pose_skeleton.global_transform * ((left + right) * 0.5)
	return global_position + Vector3.UP * 2.3

func can_see_player() -> bool:
	if not is_instance_valid(player): return false
	var origin := sight_origin()
	var target: Vector3 = player.camera.global_position
	var offset := target - origin
	if offset.length() > 15.0: return false
	var flat := Vector3(offset.x, 0.0, offset.z)
	var forward := -figure.global_basis.z
	forward.y = 0.0
	# Previous detection never grants rear vision or vision through walls.
	if flat.length() > 1.05 and forward.normalized().dot(flat.normalized()) < 0.15: return false
	# A head animation must not move the sight ray into/through solid cover.
	var neck_query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 2.3, origin, 1, [get_rid(), player.get_rid()])
	neck_query.hit_from_inside = true
	if not get_world_3d().direct_space_state.intersect_ray(neck_query).is_empty(): return false
	var query := PhysicsRayQueryParameters3D.create(origin, target, 1, [get_rid(), player.get_rid()])
	query.hit_from_inside = true
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func attention_target() -> Vector3:
	if sees_player: return player.camera.global_position
	if state == "SEARCH" and not route_path.is_empty(): return route_path[0] + Vector3.UP * 1.5
	return last_seen + Vector3.UP * 1.5

func track_player_head(delta: float, target: Vector3 = Vector3.INF) -> void:
	if not pose_skeleton or not pose_bones.has("Head"): return
	if target == Vector3.INF: target = attention_target()
	var index: int = pose_bones["Head"]
	var rest := pose_skeleton.get_bone_global_rest(index)
	var parent := pose_skeleton.get_bone_parent(index)
	var parent_basis := pose_skeleton.get_bone_global_pose(parent).basis.orthonormalized() if parent >= 0 else Basis.IDENTITY
	# Aim from the photographed eyes, not from the neck joint. Iterate as the
	# eye position itself moves around the neck pivot when the head turns.
	for iteration in range(3):
		var pose := pose_skeleton.get_bone_global_pose(index)
		var eyes := pose_skeleton.global_transform * (pose * (rest.affine_inverse() * Vector3(0,1.905,-0.26)))
		var direction: Vector3 = target - eyes
		if direction.length_squared() < 0.001: return
		var up := Vector3.FORWARD if absf(direction.normalized().dot(Vector3.UP)) > 0.98 else Vector3.UP
		var desired_world := Basis.looking_at(direction.normalized(), up)
		var desired_model := pose_skeleton.global_basis.orthonormalized().inverse() * desired_world
		var rotation := (parent_basis.inverse() * desired_model * rest.basis.orthonormalized()).get_rotation_quaternion()
		pose_skeleton.set_bone_pose_rotation(index, rotation)


# Local steering deliberately keeps the goal even when a straight line is blocked.
func plan_route(destination: Vector3) -> PackedVector3Array:
	return PackedVector3Array([destination])


func ground_at(position: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(
		position + Vector3.UP * 0.45, position - Vector3.UP * 3.0,
		collision_mask, [get_rid(), player.get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(query)


func has_safe_ground(direction: Vector3, distance: float) -> bool:
	var here := ground_at(global_position)
	if here.is_empty(): return false
	var baseline: Vector3 = here.position
	for fraction in [0.5, 1.0]:
		var ahead := ground_at(global_position + direction * distance * fraction)
		if ahead.is_empty(): return false
		var floor_point: Vector3 = ahead.position
		var normal: Vector3 = ahead.normal
		if floor_point.y < baseline.y - 0.45 or floor_point.y > baseline.y + 0.35: return false
		if normal.dot(Vector3.UP) < cos(floor_max_angle): return false
	return true


func direction_is_open(direction: Vector3, distance: float) -> bool:
	if not has_safe_ground(direction, distance): return false
	return not test_move(global_transform, direction * distance)


func steer_around_obstacles(desired: Vector3) -> Vector3:
	if desired.length_squared() < 0.01: return Vector3.ZERO
	var forward := desired.normalized()
	# Retain a preferred side so she does not switch left/right every frame.
	for degrees in [0.0, 30.0, -30.0, 60.0, -60.0, 90.0, -90.0, 125.0, -125.0, 180.0]:
		var candidate := forward.rotated(Vector3.UP, deg_to_rad(degrees * avoidance_side))
		if direction_is_open(candidate, 0.55): return candidate
	# Short probes allow movement in cramped spaces.
	for degrees in [0.0, 60.0, -60.0, 100.0, -100.0, 180.0]:
		var candidate := forward.rotated(Vector3.UP, deg_to_rad(degrees * avoidance_side))
		if direction_is_open(candidate, 0.18): return candidate
	return Vector3.ZERO


func random_walk_target() -> Vector3:
	# Prefer continuing forward, while occasionally exploring a new direction.
	var forward := -figure.global_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	for attempt in range(20):
		var angle := randf_range(-1.3, 1.3) if attempt < 10 else randf_range(-PI, PI)
		var heading := forward.rotated(Vector3.UP, angle)
		if direction_is_open(heading, 0.55):
			return global_position + heading * randf_range(1.0, maxf(1.0, wander_radius))
	return global_position
