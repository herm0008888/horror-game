extends RigidBody3D
## Ray suspension + independent axle tire forces. All tuning is Inspector editable.
@export var engine_force: float = 9500.0
@export var brake_force: float = 14500.0
@export var spring_strength: float = 42000.0
@export var damper: float = 4800.0
@export var suspension_rest: float = 0.38
@export var tire_radius: float = 0.34
@export var front_grip: float = 1.75
@export var rear_grip: float = 1.35
@export var steering_angle: float = 0.52
@export var spawn: Marker3D
@onready var axles: Array[Node] = $Suspension.get_children()
@onready var visual: Node3D = $Visual
@onready var smoke_left: GPUParticles3D = $Effects/SmokeLeft
@onready var smoke_right: GPUParticles3D = $Effects/SmokeRight
@onready var engine: AudioStreamPlayer3D = $Engine
@onready var tires: AudioStreamPlayer3D = $Tires
var speed_kmh: float = 0.0
var steer: float = 0.0
var drift_amount: float = 0.0
var reset_requested := false
var wheel_spin: float = 0.0
var home: Transform3D

func _ready() -> void:
	home = global_transform
	if spawn: home = spawn.global_transform
	for axle in axles:
		(axle as RayCast3D).add_exception(self)
	engine.play()
	tires.play()

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if reset_requested:
		state.transform = home
		state.linear_velocity = Vector3.ZERO
		state.angular_velocity = Vector3.ZERO
		reset_requested = false

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("reset_car") or global_position.y < -8.0:
		reset_requested = true
	var throttle := Input.get_action_strength("accelerate")
	var braking := Input.get_action_strength("brake")
	var handbrake := Input.is_action_pressed("handbrake")
	var forward := -global_basis.z
	var longitudinal := linear_velocity.dot(forward)
	speed_kmh = linear_velocity.length() * 3.6
	var steer_target := Input.get_axis("steer_right", "steer_left")
	steer = move_toward(steer, steer_target, delta * 3.8)
	var angle := steer * steering_angle / (1.0 + absf(longitudinal) * 0.023)
	var slip_sum := 0.0
	var grounded := 0
	for i in range(axles.size()):
		var ray := axles[i] as RayCast3D
		var wheel := ray.get_node("Wheel") as Node3D
		var front := i < 2
		wheel.rotation.y = angle if front else 0.0
		wheel.get_node("Mesh").rotation.x = wheel_spin
		if not ray.is_colliding():
			wheel.position.y = -(suspension_rest)
			continue
		grounded += 1
		var point := ray.get_collision_point()
		var normal := ray.get_collision_normal()
		var offset := point - global_position
		var velocity_at_wheel := linear_velocity + angular_velocity.cross(offset)
		var distance := ray.global_position.distance_to(point)
		var compression := suspension_rest - (distance - tire_radius)
		var load := clampf(compression * spring_strength - velocity_at_wheel.dot(normal) * damper, 0.0, 18000.0)
		apply_force(normal * load, offset)
		wheel.position.y = -clampf(distance - tire_radius, 0.05, suspension_rest + 0.15)
		var wheel_forward := forward.rotated(global_basis.y, angle if front else 0.0)
		wheel_forward = wheel_forward.slide(normal).normalized()
		var wheel_right := wheel_forward.cross(normal).normalized()
		var lateral_speed := velocity_at_wheel.dot(wheel_right)
		var wheel_speed := velocity_at_wheel.dot(wheel_forward)
		var grip := front_grip if front else rear_grip
		if not front:
			grip *= 0.20 if handbrake else lerpf(1.0, 0.68, throttle * clampf(absf(longitudinal) / 12.0, 0.0, 1.0))
		var side_force := -lateral_speed * mass * (3.2 if front else 2.7)
		side_force = clampf(side_force, -load * grip, load * grip)
		apply_force(wheel_right * side_force, offset)
		var drive := 0.0
		if not front:
			drive = throttle * engine_force * 0.5 * clampf(1.0 - maxf(longitudinal, 0.0) / 65.0, 0.0, 1.0)
		if braking > 0.0:
			if longitudinal > 0.8:
				drive -= minf(brake_force * braking * 0.25, absf(wheel_speed) * mass * 0.8)
			else:
				drive -= braking * engine_force * 0.23 * clampf(1.0 + longitudinal / 15.0, 0.0, 1.0)
		if handbrake and not front:
			drive -= clampf(wheel_speed * mass, -load * 0.6, load * 0.6)
		apply_force(wheel_forward * (drive - wheel_speed * 22.0), offset)
		slip_sum += absf(lateral_speed)
	wheel_spin -= longitudinal / tire_radius * delta
	apply_central_force(-linear_velocity * linear_velocity.length() * 0.42)
	drift_amount = clampf(slip_sum / 16.0, 0.0, 1.0) if grounded > 1 else 0.0
	var smoke := grounded > 2 and speed_kmh > 18.0 and (drift_amount > 0.3 or handbrake)
	smoke_left.emitting = smoke
	smoke_right.emitting = smoke
	visual.rotation.z = lerpf(visual.rotation.z, -steer * minf(speed_kmh / 900.0, 0.06), delta * 5.0)
	engine.pitch_scale = lerpf(engine.pitch_scale, 0.7 + fmod(absf(longitudinal) * 0.075, 1.35) + throttle * 0.35, delta * 6.0)
	engine.volume_db = -19.0 + throttle * 7.0
	tires.volume_db = lerpf(tires.volume_db, -10.0 if smoke else -65.0, delta * 7.0)
