extends MultiMeshInstance3D
@export var car: RigidBody3D
@export var capacity: int = 1200
var cursor := 0
var previous: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]

func _ready() -> void:
	multimesh.instance_count = capacity
	for i in range(capacity):
		multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO), Vector3.ZERO))

func _physics_process(_delta: float) -> void:
	if not car: return
	for side in range(2):
		var ray := car.get_node("Suspension/RearLeft" if side == 0 else "Suspension/RearRight") as RayCast3D
		if car.drift_amount < 0.3 or not ray.is_colliding() or car.speed_kmh < 15.0:
			previous[side] = Vector3.ZERO
			continue
		var point := ray.get_collision_point() + ray.get_collision_normal() * 0.012
		if previous[side] == Vector3.ZERO:
			previous[side] = point
			continue
		var segment := point - previous[side]
		if segment.length() < 0.2: continue
		if segment.length() < 3.0:
			var up := ray.get_collision_normal()
			var along := segment.normalized()
			var across := up.cross(along).normalized()
			var frame := Basis(across * 0.24, up, along * (segment.length() + 0.04))
			multimesh.set_instance_transform(cursor, Transform3D(frame, (point + previous[side]) * 0.5))
			cursor = (cursor + 1) % capacity
		previous[side] = point
