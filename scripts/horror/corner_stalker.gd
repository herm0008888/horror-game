extends Node
## Cover anchors are authored Marker3D nodes. No teleportation or through-wall leaning.
@export var approach_radius: float = 9.0
@export var peek_duration: float = 0.38
@export var cooldown_duration: float = 0.25
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
	if not enemy.has_seen_player: return
	if visible_player and active:
		active = false
		holding = false
		cooldown = cooldown_duration
		enemy.route_path.clear()
		enemy.repath = 0
	if active:
		approach_left -= delta
		if not holding and enemy.global_position.distance_to(destination) < 0.45:
			holding = true
			remaining = peek_duration
			peek_count += 1
			recent_corners[chosen_corner] = Time.get_ticks_msec()
			freeze_left = 0
			burst_left = 1.3
		if holding:
			remaining -= delta
			lean = move_toward(lean, 1.0 if remaining > 0.12 else 0.0, delta*14.0)
		if (holding and remaining <= 0) or approach_left <= 0 or enemy.global_position.distance_to(enemy.player.global_position) < 2.5:
			active = false
			holding = false
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
	for node in get_tree().get_nodes_in_group("creature_cover"):
		var marker := node as Marker3D
		if Time.get_ticks_msec()-int(recent_corners.get(marker.get_instance_id(),-10000)) < 6000: continue
		var distance: float = enemy.global_position.distance_to(marker.global_position)
		if distance > minf(best_distance,1.0) or marker.global_position.distance_to(enemy.last_seen) < 2.5: continue
		if marker.global_position.distance_to(enemy.last_seen) > enemy.global_position.distance_to(enemy.last_seen)+0.15: continue
		var origin := marker.global_position + Vector3.UP * 2.3
		var offset: Vector3 = marker.get_meta("peek_offset", Vector3.ZERO)
		if ray_clear(origin,target): continue
		if not ray_clear(origin,origin+offset): continue
		if not ray_clear(origin+offset,target): continue
		best = marker
		best_distance = distance
	if best:
		active = true
		holding = false
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
	if lean < 0.001 or not skeleton or not bones.has("Spine"): return
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

