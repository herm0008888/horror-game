extends CharacterBody3D
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera
@onready var torch: SpotLight3D = $Head/Camera/Flashlight
@onready var steps: AudioStreamPlayer3D = $Steps
var pitch: float = 0.0
var spawn := Transform3D.IDENTITY
var foot_timer: float = 0.0
var look_target: Node
var bob: float = 0.0

func _ready() -> void:
	spawn = global_transform
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * 0.0024)
		pitch = clampf(pitch - event.relative.y * 0.0024, -1.35, 1.35)
	if event.is_action_pressed("release_mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseButton and event.pressed: Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("flashlight"): torch.visible = not torch.visible
	if event.is_action_pressed("interact") and is_instance_valid(look_target): look_target.interact()
	if event.is_action_pressed("restart"): reset_position()

func reset_position() -> void:
	global_transform = spawn
	velocity = Vector3.ZERO
	pitch = 0.0

func _physics_process(delta: float) -> void:
	var crouching := Input.is_action_pressed("crouch")
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := global_basis * Vector3(input.x, 0, input.y)
	var speed := 1.05 if crouching else 2.5
	velocity.x = move_toward(velocity.x, direction.x * speed, delta * 12.0)
	velocity.z = move_toward(velocity.z, direction.z * speed, delta * 12.0)
	velocity.y = -0.5 if is_on_floor() else velocity.y - delta * 18.0
	move_and_slide()
	var moving := Vector2(velocity.x, velocity.z).length() > 0.2 and is_on_floor()
	if moving: bob += delta * speed * 4.0
	head.position.y = lerpf(head.position.y, (1.08 if crouching else 1.65) + (sin(bob * 2.0) * 0.009 if moving else 0.0), 1.0 - exp(-delta * 12.0))
	head.rotation.x = pitch
	foot_timer -= delta
	if moving and foot_timer <= 0.0:
		steps.pitch_scale = randf_range(0.8, 1.12)
		steps.volume_db = -29.0 if crouching else -19.0
		steps.play()
		foot_timer = 0.7 if crouching else 0.5
		if not crouching: get_tree().call_group("horror_listener", "hear_noise", global_position, 5.0)
	look_target = null
	var ray := PhysicsRayQueryParameters3D.create(camera.global_position, camera.global_position - camera.global_basis.z * 2.6, 1, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	if not hit.is_empty():
		var node: Node = hit.collider
		while node:
			if node.has_method("interact"):
				look_target = node
				break
			node = node.get_parent()
	if position.y < -9.0: reset_position()
