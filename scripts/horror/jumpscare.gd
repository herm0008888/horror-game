extends Node
@export var hold_time: float = 1.12
@export var restart_time: float = 2.8
@export var camera_shake_amount: float = 0.022
@export var head_shake_amount: float = 0.16
@export var pull_begin: float = 0.25
@export var entry_time: float = 1.0
@export var swallow_time: float = 1.3
var phase: String = "IDLE"
var entry_pose: Node3D
var end_pose: Node3D
var light: SpotLight3D
var light_base: float = 0
var active := false
var dead := false
var elapsed: float = 0
var enemy: Node3D
var camera: Camera3D
var face: Vector3
var face_forward := Vector3.FORWARD
var head_rotation: Quaternion
var mesh_nodes: Array[MeshInstance3D] = []
var black: ColorRect
var setup: Node3D
var shake_pivot: Node3D
var shake_base: Transform3D
func _ready() -> void:
	black = $DeathUI/Black
	black.color.a = 0.0
func _exit_tree() -> void: apply_opening(0.0)
func collect(node: Node) -> void:
	if node is MeshInstance3D and node.mesh: mesh_nodes.append(node)
	for child in node.get_children(): collect(child)
func apply_opening(value: float) -> void:
	for node in mesh_nodes:
		if not is_instance_valid(node): continue
		var shape := node.find_blend_shape_by_name("Scream")
		if shape >= 0: node.set_blend_shape_value(shape,value)
		for surface in range(node.mesh.get_surface_count()):
			var material := node.get_active_material(surface) as ShaderMaterial
			if material and (material.shader.resource_path.ends_with("reference_face.gdshader") or material.shader.resource_path.ends_with("corpse_skin.gdshader")): material.set_shader_parameter("scream",value)
func begin(target: Node3D) -> void:
	if active: return
	mesh_nodes.clear()
	dead = false
	black.color.a = 0.0
	enemy = target
	enemy.velocity = Vector3.ZERO
	enemy.figure.position = Vector3.ZERO
	enemy.figure.rotation.x = 0
	enemy.figure.rotation.z = 0
	enemy.corner.active = false
	enemy.corner.holding = false
	enemy.corner.lean = 0
	var skeleton: Skeleton3D = enemy.pose_skeleton
	for bone in enemy.pose_bones:
		skeleton.set_bone_pose_rotation(enemy.pose_bones[bone],enemy.pose_rest_rotations[bone])
	setup = enemy.get_node("Figure/JumpscareSetup")
	shake_pivot = setup.get_node("CameraShake")
	shake_base = shake_pivot.transform
	entry_pose = setup.get_node("MouthEntry")
	end_pose = setup.get_node("SwallowEnd")
	camera = shake_pivot.get_node("JumpscareCamera")
	var pose_node: Marker3D = setup.get_node("HeadPose")
	var index: int = enemy.pose_bones["Head"]
	head_rotation = enemy.pose_rest_rotations["Head"] * Quaternion.from_euler(pose_node.rotation)
	skeleton.set_bone_pose_rotation(index,head_rotation)
	face = setup.get_node("FaceTarget").global_position
	face_forward = -setup.global_basis.z.normalized()
	get_parent().torch.visible = false
	light = setup.get_node("CameraShake/JumpscareCamera/FaceLight")
	light_base = light.light_energy
	light.visible = true
	enemy.get_node("PathDebug").visible = false
	camera.make_current()
	collect(enemy.figure)
	apply_opening(0.0)
	# Use the authored impact sound at its existing mix level.
	get_parent().get_node("Caught").play()
	get_tree().call_group("horror_overlay", "set_caught")
	elapsed = 0
	phase = "OPEN"
	active = true
	# Apply the attack pose in the capture call, before the first rendered frame.
	_process(0.0)
func _process(delta: float) -> void:
	if not active: return
	elapsed += delta
	var impact := 1.0 - smoothstep(0.06, 0.28, elapsed)
	var second_hit := smoothstep(0.57, 0.60, elapsed) * (1.0 - smoothstep(0.64, 0.80, elapsed))
	var shaking := maxf(impact, second_hit) if elapsed < hold_time else 0.0
	# All composition comes from saved editor nodes. Only the parent pivot shakes.
	var pull := smoothstep(pull_begin,entry_time,elapsed)
	var swallow := smoothstep(entry_time,swallow_time,elapsed)
	shake_pivot.transform = shake_base.interpolate_with(entry_pose.transform,pull)
	# Keep the original lunge/recoil and second hit, but pull continuously between them.
	var lunge := (1.0 - smoothstep(0.0, 0.09, elapsed)) * -0.65
	var recoil := smoothstep(0.09, 0.14, elapsed) * (1.0 - smoothstep(0.14, 0.25, elapsed)) * -0.10
	shake_pivot.position.z += lunge + recoil + second_hit * 0.07
	if elapsed >= entry_time: shake_pivot.transform = entry_pose.transform.interpolate_with(end_pose.transform,swallow)
	phase = "BITE" if elapsed >= entry_time else ("PULL_IN" if elapsed >= pull_begin else "OPEN")
	light.light_energy = light_base * (1.0 + impact * 0.6) * (1.0-smoothstep(0.85,1.15,elapsed))
	shake_pivot.position += Vector3(sin(elapsed*103),sin(elapsed*127),sin(elapsed*89)*0.4)*camera_shake_amount*shaking
	shake_pivot.rotation += Vector3(sin(elapsed*113)*0.006,0,sin(elapsed*109)*0.012)*shaking
	var skeleton: Skeleton3D = enemy.pose_skeleton
	var index: int = enemy.pose_bones["Head"]
	var snapped := sin(floor(elapsed * 24.0) * 2.399)
	var twitch := Vector3(snapped * head_shake_amount, sin(elapsed * 61.0) * head_shake_amount * 0.4, snapped * head_shake_amount * 0.8) * shaking
	skeleton.set_bone_pose_rotation(index,head_rotation*Quaternion.from_euler(twitch))
	var reaching := smoothstep(0.0,0.12,elapsed)
	for pose in setup.get_node("ReachPoses").get_children():
		var bone: String = pose.get_meta("bone","")
		if enemy.pose_bones.has(bone):
			var rotation: Quaternion = enemy.pose_rest_rotations[bone]*Quaternion.from_euler(pose.rotation*reaching)
			skeleton.set_bone_pose_rotation(enemy.pose_bones[bone],rotation)
	var opening := smoothstep(0.0,0.085,elapsed)
	var bite := smoothstep(1.10,1.35,elapsed)
	apply_opening(opening*(1.0-bite*0.35)*(1.0-smoothstep(1.45,1.65,elapsed)))
	enemy.eye_gaze.track(camera.global_position,delta)
	if enemy.pose_bones.has("Tongue"):
		var tongue_index: int = enemy.pose_bones["Tongue"]
		var tongue_pose: Quaternion = enemy.pose_rest_rotations["Tongue"]*Quaternion.from_euler(Vector3(sin(elapsed*17.0)*0.025,0,sin(elapsed*13.0)*0.018)*opening)
		skeleton.set_bone_pose_rotation(tongue_index,tongue_pose)
	if elapsed > hold_time:
		dead = true
		phase = "DEAD"
		black.color.a = clampf((elapsed-hold_time)/0.10,0,1)
	if elapsed > restart_time:
		active = false
		get_tree().reload_current_scene()

