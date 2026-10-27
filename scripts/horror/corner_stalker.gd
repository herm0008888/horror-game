extends Node
## Cover anchors are authored Marker3D nodes. No teleportation or through-wall leaning.
@export var approach_radius: float = 9.0
@export var settle_duration: float = 0.65
@export var lean_duration: float = 0.85
@export var peek_duration: float = 1.15
@export var withdraw_duration: float = 0.28
@export var cooldown_duration: float = 2.5
var peek_elapsed: float = 0.0
var peek_phase: String = "IDLE"
var active := false
var holding := false
var destination := Vector3.ZERO
var peek_offset := Vector3.ZERO
var lean: float = 0.0
var cooldown: float = 1.5
var remaining: float = 0.0
var approach_left: float = 0.0
var freeze_left: float = 0.0
var stare_cooldown: float = 0.0
var burst_left: float = 0.0
var peek_count: int = 0
var recent_corners: Dictionary = {}
var chosen_corner: int = 0
var enemy: CharacterBody3D

func _ready() -> void: enemy = get_parent()

func ray_clear(start: Vector3, finish: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(start, finish, 1, [enemy.get_rid(), enemy.player.get_rid()])
	return enemy.get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func tick(delta: float, visible_player: bool) -> void:
	cooldown -= delta
	stare_cooldown -= delta
	freeze_left = maxf(0, freeze_left-delta)
	burst_left = maxf(0, burst_left-delta)
	if not active and not enemy.has_seen_player and enemy.state != "INVESTIGATE": return
	if visible_player and active and not holding:
		active = false
		holding = false
		cooldown = cooldown_duration
		enemy.route_path.clear()
		enemy.repath = 0
	if active:
		approach_left -= delta
		if not holding and enemy.global_position.distance_to(destination) < 0.45:
			holding = true
			peek_elapsed = 0.0
			remaining = settle_duration + lean_duration + peek_duration + withdraw_duration
			peek_phase = "SETTLE"
			peek_count += 1
			recent_corners[chosen_corner] = Time.get_ticks_msec()
			# Treat both edges of the same cover as one inspection, not a peek loop.
			for marker in get_tree().get_nodes_in_group("creature_cover"):
				if marker.global_position.distance_to(destination) < 4.3:
					recent_corners[marker.get_instance_id()] = Time.get_ticks_msec()
			freeze_left = 0
			burst_left = 0.0
		if holding:
			peek_elapsed += delta
			remaining -= delta
			var reveal_end := settle_duration + lean_duration
			var stare_end := reveal_end + peek_duration
			if peek_elapsed < settle_duration:
				peek_phase = "SETTLE"
				lean = 0.0
			elif peek_elapsed < reveal_end:
				peek_phase = "REVEAL"
				lean = smoothstep(settle_duration, reveal_end, peek_elapsed)
			elif peek_elapsed < stare_end:
				peek_phase = "STARE"
				lean = 1.0
			else:
				peek_phase = "WITHDRAW"
				lean = 1.0 - smoothstep(stare_end, stare_end + withdraw_duration, peek_elapsed)
		if (holding and remaining <= 0) or approach_left <= 0 or (visible_player and enemy.global_position.distance_to(enemy.player.global_position) < 1.5):
			active = false
			holding = false
			peek_phase = "IDLE"
			burst_left = 1.3
			cooldown = cooldown_duration
			enemy.route_path.clear()
			enemy.repath = 0
		return
	lean = move_toward(lean, 0, delta*10.0)
	var camera: Camera3D = enemy.player.camera
	var toward_enemy: Vector3 = (enemy.global_position+Vector3.UP*2.0-camera.global_position).normalized()
	if visible_player and stare_cooldown <= 0 and enemy.global_position.distance_to(enemy.player.global_position) > 4.0 and (-camera.global_basis.z).dot(toward_enemy) > 0.98:
		freeze_left = 0.22
		burst_left = 1.9
		stare_cooldown = 7.0
	if visible_player: return
	if cooldown > 0: return
	cooldown = 0.08
	var best: Marker3D
	var best_distance: float = approach_radius
	# Investigate the last seen position; cover choice doesn't reveal unseen movement.
	var target: Vector3 = enemy.last_seen + Vector3.UP * 1.65
	var memory_path: PackedVector3Array = enemy.plan_route(enemy.last_seen)
	for node in get_tree().get_nodes_in_group("creature_cover"):
		var marker := node as Marker3D
		if Time.get_ticks_msec()-int(recent_corners.get(marker.get_instance_id(),-10000)) < 6000: continue
		var distance: float = enemy.global_position.distance_to(marker.global_position)
		if distance > best_distance or marker.global_position.distance_to(enemy.last_seen) < 0.65: continue
		if absf(marker.global_position.y - enemy.global_position.y) > 0.65: continue
		if marker.global_position.distance_to(enemy.last_seen) > enemy.global_position.distance_to(enemy.last_seen)+0.75: continue
		if not enemy.clear_passage(enemy.global_position, marker.global_position): continue
		# Follow the route to the remembered clue, not the player's hidden position.
		var on_route := distance < 0.6
		var previous: Vector3 = enemy.global_position
		for point in memory_path:
			if Geometry3D.get_closest_point_to_segment(marker.global_position, previous, point).distance_to(marker.global_position) < 1.0:
				on_route = true
			previous = point
		if not on_route: continue
		var origin := marker.global_position + Vector3.UP * 2.3
		var offset: Vector3 = marker.get_meta("peek_offset", Vector3.ZERO)
		# Authored cover can be inspected even when the last clue was at its edge.
		if not ray_clear(origin,origin+offset): continue
		if not ray_clear(origin+offset,target): continue
		best = marker
		best_distance = distance
	if best:
		active = true
		holding = false
		peek_phase = "APPROACH"
		destination = best.global_position
		chosen_corner = best.get_instance_id()
		peek_offset = best.get_meta("peek_offset", Vector3.ZERO)
		approach_left = 9.0
		enemy.route_path.clear()
		enemy.repath = 0

func speed_factor() -> float:
	if holding or freeze_left > 0: return 0.0
	return 1.35 if burst_left > 0 else 1.0

func pose_lean(skeleton: Skeleton3D, bones: Dictionary) -> void:
	if not skeleton or not bones.has("Spine"): return
	if holding:
		# Anchor the feet and hanging arms; only the upper body reveals itself.
		for bone in ["LegLeft", "LegRight", "ArmLeft", "ArmRight", "ForearmLeft", "ForearmRight"]:
			if bones.has(bone): skeleton.set_bone_pose_rotation(bones[bone], enemy.pose_rest_rotations[bone])
	if not holding and lean < 0.001: return
	var index: int = bones["Spine"]
	var parent := skeleton.get_bone_parent(index)
	var parent_basis := skeleton.get_bone_global_pose(parent).basis.orthonormalized() if parent >= 0 else Basis.IDENTITY
	var direction := peek_offset.normalized()
	var axis := Vector3.UP.cross(direction).normalized()
	var tilt := Basis(Quaternion(axis, 0.78*lean))
	var basis := skeleton.global_basis.orthonormalized()
	var neutral_local := Basis(enemy.pose_rest_rotations["Spine"]) * Basis.from_euler(Vector3(-enemy.motion.body_hunch,0.055,-0.055))
	var neutral_global := parent_basis * neutral_local
	var desired := basis.inverse()*tilt*basis*neutral_global
	skeleton.set_bone_pose_rotation(index,(parent_basis.inverse()*desired).get_rotation_quaternion())

func pose_head(skeleton: Skeleton3D, bones: Dictionary) -> void:
	if not holding or not skeleton or not bones.has("Head"): return
	var index: int = bones["Head"]
	var side := signf(enemy.figure.global_basis.x.dot(peek_offset))
	# Eyes still track the player, while the head gradually cocks to one side.
	var tilt := Quaternion.from_euler(Vector3(-0.06 * lean, 0.0, side * 0.24 * lean))
	skeleton.set_bone_pose_rotation(index, skeleton.get_bone_pose_rotation(index) * tilt)

