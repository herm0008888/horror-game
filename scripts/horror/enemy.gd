extends CharacterBody3D
@export var player: CharacterBody3D
@export var route: Node3D
@export var patrol_speed: float = 1.15
@export var chase_speed: float = 2.65
@onready var figure: Node3D = $Figure
@onready var motion: Node = $HauntedMotion
@onready var corner: Node = $CornerStalker
@onready var eye_gaze: Node = $EyeGaze
@onready var breath: AudioStreamPlayer3D = $Breath
var graph := AStar3D.new()
var points: Array[Vector3] = []
var patrol_index := 0
var route_path := PackedVector3Array()
var repath: float = 0
var hunt: float = 0
var gait: float = 0
var waiting_door: Node3D
var has_seen_player := false
var caught := false
var state: String = "PATROL"
var search_left: float = 0.0
var search_origin := Vector3.ZERO
var search_step: int = 0
var previous_position := Vector3.ZERO
var stuck_time: float = 0.0
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
	for marker in route.get_children():
		if marker is Marker3D:
			points.append(marker.global_position)
			graph.add_point(points.size() - 1, marker.global_position)
	for marker in route.get_children():
		if marker is Marker3D:
			var from: int = marker.get_index()
			for to in marker.get_meta("links", PackedInt32Array()):
				if not graph.are_points_connected(from, to): graph.connect_points(from, to)
	breath.play()

func _physics_process(delta: float) -> void:
	if not player or caught: return
	var offset := player.global_position - global_position
	var distance := offset.length()
	var same_floor := absf(offset.y) < 2.0
	var visible_player := false
	if distance < 15 and same_floor:
		var origin := global_position + Vector3.UP * 2.3
		var end := player.global_position + Vector3.UP * 1.2
		var hit := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(origin, end, 1, [get_rid(), player.get_rid()]))
		var facing := -figure.global_basis.z
		visible_player = hit.is_empty() and (has_seen_player or facing.dot(offset.normalized()) > 0.15 or distance < 3.2)
	if visible_player:
		has_seen_player = true
		if state != "CHASE": route_path.clear()
		state = "CHASE"
		hunt = 7.0
		last_seen = player.global_position
	elif hunt > 0:
		hunt = maxf(0, hunt - delta)
		if hunt <= 0: begin_search()
	if state == "SEARCH":
		search_left -= delta
		if search_left <= 0:
			state = "PATROL"
			route_path.clear()
	corner.tick(delta, visible_player)
	repath -= delta
	if repath <= 0 and points.size() > 0 and (route_path.is_empty() or (state == "CHASE" and visible_player)):
		repath = 0.55
		var destination := points[patrol_index]
		if state in ["CHASE", "INVESTIGATE"]:
			destination = last_seen
			if global_position.distance_to(last_seen) < 0.85 and not visible_player:
				begin_search()
		elif state == "SEARCH":
			var center := graph.get_closest_point(search_origin)
			var neighbors := graph.get_point_connections(center)
			if neighbors.size() > 0:
				destination = graph.get_point_position(neighbors[search_step % neighbors.size()])
				search_step += 1
		else:
			if global_position.distance_to(destination) < 1:
				patrol_index = (patrol_index + 1) % points.size()
				destination = points[patrol_index]
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
	var speed: float = (chase_speed if hunt > 0 else patrol_speed) * motion.speed_factor(hunt > 0) * corner.speed_factor()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if not is_on_floor(): velocity.y -= delta * 18
	else: velocity.y = -0.5
	move_and_slide()
	if direction.length() > 0.1 and global_position.distance_to(previous_position) < delta * 0.10:
		stuck_time += delta
	else: stuck_time = 0.0
	previous_position = global_position
	if stuck_time > 2.0:
		route_path.clear()
		repath = 0
		stuck_time = 0
		if state == "PATROL": patrol_index = (patrol_index + 1) % points.size()
	if direction.length() > 0.1:
		figure.rotation.y = lerp_angle(figure.rotation.y, atan2(-direction.x, -direction.z), delta * 8)
	motion.animate(delta, direction.length() > 0.1, hunt > 0, figure, pose_skeleton, pose_bones, pose_rest_rotations)
	corner.pose_lean(pose_skeleton, pose_bones)
	if has_seen_player:
		track_player_head(delta)
		eye_gaze.track(player.camera.global_position,delta)
	breath.pitch_scale = 0.84 + (0.16 if hunt > 0 else 0)
	if distance < 1.05 and same_floor and visible_player and not player.caught:
		caught = true
		player.capture(self)

func hear_noise(source: Vector3, radius: float) -> void:
	if caught or state == "CHASE": return
	if global_position.distance_to(source) > radius: return
	# Sound carries between floors; A* takes the stairs instead of a straight line.
	last_seen = source
	state = "INVESTIGATE"
	hunt = 12.0
	route_path.clear()
	repath = 0.0

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

func track_player_head(delta: float) -> void:
	if not pose_skeleton or not pose_bones.has("Head"): return
	var index: int = pose_bones["Head"]
	var rest := pose_skeleton.get_bone_global_rest(index)
	var parent := pose_skeleton.get_bone_parent(index)
	var parent_basis := pose_skeleton.get_bone_global_pose(parent).basis.orthonormalized() if parent >= 0 else Basis.IDENTITY
	# Aim from the photographed eyes, not from the neck joint. Iterate as the
	# eye position itself moves around the neck pivot when the head turns.
	for iteration in range(3):
		var pose := pose_skeleton.get_bone_global_pose(index)
		var eyes := pose_skeleton.global_transform * (pose * (rest.affine_inverse() * Vector3(0,1.905,-0.26)))
		var direction: Vector3 = player.camera.global_position - eyes
		if direction.length_squared() < 0.001: return
		var up := Vector3.FORWARD if absf(direction.normalized().dot(Vector3.UP)) > 0.98 else Vector3.UP
		var desired_world := Basis.looking_at(direction.normalized(), up)
		var desired_model := pose_skeleton.global_basis.orthonormalized().inverse() * desired_world
		var rotation := (parent_basis.inverse() * desired_model * rest.basis.orthonormalized()).get_rotation_quaternion()
		pose_skeleton.set_bone_pose_rotation(index, rotation)


func plan_route(destination: Vector3) -> PackedVector3Array:
	if clear_passage(global_position,destination): return PackedVector3Array([destination])
	var candidates: Array[Vector3] = points.duplicate()
	for marker in get_tree().get_nodes_in_group("creature_cover"):
		candidates.append(marker.global_position)
	for obstacle in get_tree().get_nodes_in_group("navigation_obstacle"):
		var collider := obstacle.get_node_or_null("Collision") as CollisionShape3D
		if not collider or not collider.shape is BoxShape3D: continue
		var half: Vector3 = collider.shape.size * 0.5 + Vector3(0.34,0,0.34)
		for side in [-1,1]:
			for end in [-1,1]:
				var corner_point: Vector3 = collider.global_transform * Vector3(half.x*side,0,half.z*end)
				corner_point.y = destination.y
				candidates.append(corner_point)
	var navigation := AStar3D.new()
	candidates.append(global_position)
	var start := candidates.size()-1
	candidates.append(destination)
	var finish := candidates.size()-1
	for i in range(candidates.size()): navigation.add_point(i,candidates[i])
	for i in range(candidates.size()):
		for j in range(i+1,candidates.size()):
			if clear_passage(candidates[i],candidates[j]): navigation.connect_points(i,j)
	var path := navigation.get_point_path(start,finish)
	if path.size() > 0: path.remove_at(0)
	return path


