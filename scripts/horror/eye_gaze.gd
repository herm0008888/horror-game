extends Node
@export var response_speed: float = 45.0
var skeleton: Skeleton3D
var eyes: Array[int] = []
func _ready() -> void:
	call_deferred("bind_eyes")
func bind_eyes() -> void:
	var enemy := get_parent()
	skeleton = enemy.pose_skeleton
	if not skeleton: return
	for name in ["EyeLeft","EyeRight"]:
		var index := skeleton.find_bone(name)
		if index >= 0: eyes.append(index)
func track(target: Vector3, delta: float) -> void:
	if not skeleton: return
	for index in eyes:
		var pose := skeleton.get_bone_global_pose(index)
		var position := skeleton.global_transform*pose.origin
		var direction := target-position
		if direction.length_squared() < 0.0001: continue
		var up := Vector3.FORWARD if absf(direction.normalized().dot(Vector3.UP)) > 0.98 else Vector3.UP
		var desired := Basis.looking_at(direction.normalized(),up)
		var parent := skeleton.get_bone_parent(index)
		var parent_basis := skeleton.get_bone_global_pose(parent).basis.orthonormalized()
		var rest := skeleton.get_bone_global_rest(index).basis.orthonormalized()
		var local_rotation := (parent_basis.inverse()*skeleton.global_basis.orthonormalized().inverse()*desired*rest).get_rotation_quaternion()
		skeleton.set_bone_pose_rotation(index,skeleton.get_bone_pose_rotation(index).slerp(local_rotation,1.0-exp(-delta*response_speed)))
