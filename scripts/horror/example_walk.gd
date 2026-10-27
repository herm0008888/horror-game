extends CharacterBody3D
var pitch: float = -0.08
@onready var head: Node3D = $Head
@onready var torch: SpotLight3D = $Head/Camera/Flashlight
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
func acquire_flashlight() -> void: pass
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * 0.0024)
		pitch = clampf(pitch - event.relative.y * 0.0024, -1.3, 1.3)
	if event.is_action_pressed("release_mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseButton and event.pressed: Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("flashlight"): torch.visible = not torch.visible
func _physics_process(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := global_basis * Vector3(input.x, 0, input.y)
	velocity.x = direction.x * 2.2
	velocity.z = direction.z * 2.2
	velocity.y = -0.5 if is_on_floor() else velocity.y - delta * 18.0
	head.rotation.x = pitch
	move_and_slide()
