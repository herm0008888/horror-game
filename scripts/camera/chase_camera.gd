extends Camera3D
@export var target: RigidBody3D
@export var follow_distance: float = 7.2
@export var height: float = 3.0
@export var look_height: float = 0.65
@export var smoothing: float = 6.0
var initialized := false

func _physics_process(delta: float) -> void:
	if not target: return
	var forward := -target.global_basis.z
	var movement := target.linear_velocity
	movement.y = 0.0
	var direction := forward
	if movement.length() > 4.0:
		direction = forward.lerp(movement.normalized(), 0.28).normalized()
	var desired := target.global_position - direction * follow_distance + Vector3.UP * height
	var focus := target.global_position + Vector3.UP * look_height + forward * 1.5
	var query := PhysicsRayQueryParameters3D.create(focus, desired, 1, [target.get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty(): desired = hit.position + hit.normal * 0.4
	if not initialized or global_position.distance_to(desired) > 35.0:
		global_position = desired
		initialized = true
	else:
		global_position = global_position.lerp(desired, 1.0 - exp(-smoothing * delta))
	look_at(focus)
	fov = lerpf(fov, 65.0 + minf(target.linear_velocity.length() * 0.35, 14.0), delta * 2.0)
