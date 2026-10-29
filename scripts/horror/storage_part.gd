extends AnimatableBody3D
## Authored pivots, offsets and item slots are editable in the furniture scene.
@export var open_offset: Vector3 = Vector3.ZERO
@export var open_rotation_degrees: Vector3 = Vector3.ZERO
@export_range(0.1,1.5) var duration: float = 0.38
var opened:=false
var closed_transform: Transform3D
var motion: Tween
func _ready() -> void:
	sync_to_physics=false
	closed_transform=transform
	add_to_group("openable_storage")
func interact() -> void:
	var player:=get_tree().get_first_node_in_group("horror_player") as Node3D
	if player and player.global_position.distance_to(global_position)>3.3: return
	set_open(not opened)
func set_open(enabled: bool, immediate: bool=false) -> void:
	if opened==enabled and not immediate: return
	opened=enabled
	get_tree().call_group("dynamic_navigation","request_update")
	if motion and motion.is_valid(): motion.kill()
	var target:=closed_transform
	if opened:
		target.origin+=open_offset
		target.basis=Basis.from_euler(open_rotation_degrees*PI/180.0)*closed_transform.basis
	if immediate:
		transform=target
		return
	motion=create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	motion.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	motion.tween_property(self,"transform",target,duration)
