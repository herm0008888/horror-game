extends CharacterBody3D
var pitch: float = 0.0
var crouched := false
var start := Vector3(6, 0.1, 14)
@onready var capsule: CollisionShape3D = $Collision
@onready var camera: Camera3D = $Camera
func _ready() -> void:
	add_to_group("horror_player")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
func _unhandled_input(event: InputEvent) -> void:
	if (event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and event.physical_keycode==KEY_E)) and not event.is_echo():
		var ray := PhysicsRayQueryParameters3D.create(camera.global_position,camera.global_position-camera.global_basis.z*2.6,1,[get_rid()])
		var hit := get_world_3d().direct_space_state.intersect_ray(ray)
		if not hit.is_empty() and hit.collider.has_method("interact"):
			hit.collider.interact()
			get_viewport().set_input_as_handled()
			return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotation.y -= event.relative.x * 0.0024
		pitch = clampf(pitch - event.relative.y * 0.0024, -1.4, 1.4)
		camera.rotation.x = pitch
	if event.is_action_pressed("release_mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("restart"):
		position = start
		velocity = Vector3.ZERO
func can_stand() -> bool:
	var shape := CapsuleShape3D.new()
	shape.radius = 0.25
	shape.height = 1.7
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, global_position + Vector3.UP * 0.86)
	query.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_shape(query).is_empty()
func _physics_process(delta: float) -> void:
	crouched = Input.is_action_pressed("crouch") or (crouched and not can_stand())
	var height: float = 0.95 if crouched else 1.7
	capsule.shape.height = height
	capsule.position.y = height * 0.5 + 0.01
	camera.position.y = lerpf(camera.position.y, 0.8 if crouched else 1.6, minf(1, delta * 15))
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := global_basis * Vector3(input.x, 0, input.y)
	velocity.x = direction.x * (1.5 if crouched else 3.0)
	velocity.z = direction.z * (1.5 if crouched else 3.0)
	velocity.y = -0.5 if is_on_floor() else velocity.y - 20 * delta
	move_and_slide()
	if position.y < -9:
		position = start

func acquire_flashlight() -> void:
	$Camera/FlashlightRig.acquire()
