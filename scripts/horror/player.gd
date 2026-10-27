extends CharacterBody3D
@export var walk_speed: float = 2.25
@export var crouch_speed: float = 1.0
@export var sensitivity: float = 0.0024
@export_range(0.0, 0.03) var camera_bob: float = 0.018
@export_range(0.0, 0.08) var camera_lean: float = 0.028
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera
@onready var torch: SpotLight3D = $Head/Camera/Flashlight
@onready var steps: AudioStreamPlayer3D = $Footsteps
@onready var held_torch: Node3D = $Head/Camera/HeldFlashlight
var has_flashlight := false
var look_sway := Vector2.ZERO
var spawn: Transform3D
var sprinting := false
var crouching := false
var caught := false
var pitch: float = 0
var bob: float = 0
var foot_timer: float = 0

func _exit_tree() -> void:
	steps.stop()
	$Caught.stop()

func _ready() -> void:
	spawn = global_transform
	torch.visible = false
	held_torch.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not caught:
		rotate_y(-event.relative.x * sensitivity)
		look_sway = (look_sway + event.relative * 0.00045).clamp(Vector2(-0.04,-0.04), Vector2(0.04,0.04))
		pitch = clampf(pitch - event.relative.y * sensitivity, -1.35, 1.35)
	if event.is_action_pressed("release_mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("flashlight") and has_flashlight and not caught: torch.visible = not torch.visible
	if event.is_action_pressed("restart"): get_tree().reload_current_scene()
	if event.is_action_pressed("interact") and not caught:
		var query := PhysicsRayQueryParameters3D.create(camera.global_position, camera.global_position - camera.global_basis.z * 2.4, 1, [get_rid()])
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			var node: Node = hit.collider
			while node:
				if node.has_method("interact"):
					node.interact()
					break
				node = node.get_parent()

func _physics_process(delta: float) -> void:
	if caught: return
	crouching = Input.is_action_pressed("crouch")
	sprinting = false
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := global_basis * Vector3(input.x, 0, input.y)
	var speed := crouch_speed if crouching else walk_speed
	var response := 3.8 if input.length() > 0.1 else 6.5
	velocity.x = move_toward(velocity.x, direction.x * speed, delta * response)
	velocity.z = move_toward(velocity.z, direction.z * speed, delta * response)
	if not is_on_floor(): velocity.y -= 18 * delta
	else: velocity.y = -0.5
	move_and_slide()
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var moving := horizontal_speed > 0.15 and is_on_floor()
	bob += delta * horizontal_speed * 4.4 if moving else 0.0
	var weight := clampf(horizontal_speed / walk_speed, 0, 1)
	var vertical := (cos(bob * 2.0) - 1.0) * camera_bob * 0.5 * weight if moving else 0.0
	var lateral := sin(bob) * camera_bob * 0.65 * weight if moving else 0.0
	head.position = head.position.lerp(Vector3(lateral, (0.95 if crouching else 1.65) + vertical, 0), 1.0-exp(-delta*12))
	head.rotation.x = lerp_angle(head.rotation.x, pitch, 1.0-exp(-delta*24))
	look_sway = look_sway.lerp(Vector2.ZERO, 1.0-exp(-delta*7))
	var local_velocity := global_basis.inverse() * velocity
	camera.rotation.y = -look_sway.x
	camera.rotation.x = -look_sway.y
	camera.rotation.z = lerpf(camera.rotation.z, -local_velocity.x/walk_speed*camera_lean-look_sway.x*0.4+sin(bob)*0.003*weight, 1.0-exp(-delta*7))
	held_torch.rotation.x = lerpf(held_torch.rotation.x, look_sway.y*1.8, 1.0-exp(-delta*12))
	held_torch.rotation.y = lerpf(held_torch.rotation.y, look_sway.x*1.8, 1.0-exp(-delta*12))
	if moving:
		foot_timer -= delta
		if foot_timer <= 0:
			steps.pitch_scale = randf_range(0.86, 1.12)
			steps.volume_db = -27 if crouching else -17
			steps.play()
			if not crouching: get_tree().call_group("horror_listener", "hear_noise", global_position, 4.8)
			foot_timer = 0.68 if not crouching else 0.85
	else: foot_timer = 0.1
	torch.light_energy = 2.9 + sin(Time.get_ticks_msec() * 0.033) * 0.01
	if position.y < -5: global_transform = spawn

func capture(enemy: Node3D) -> void:
	if caught: return
	caught = true
	velocity = Vector3.ZERO
	$Footsteps.stop()
	$Caught.stop()
	held_torch.visible = false
	enemy.caught = true
	enemy.breath.stop()
	$Jumpscare.begin(enemy)

func acquire_flashlight() -> void:
	has_flashlight = true
	torch.visible = true
	held_torch.visible = true

