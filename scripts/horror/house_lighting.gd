extends Node3D
signal mode_changed(normal: bool)
## L switches between the authored horror lights and the original bright work lighting.
@export var normal_lighting: bool = false
@export_node_path("WorldEnvironment") var environment_node: NodePath
@export var horror_environment: Environment
@export var normal_environment: Environment
@export_range(0.0,0.15) var flicker_amount: float = 0.065
var elapsed: float = 0.0
@onready var horror_lights: Node3D = $HorrorLights
@onready var environment: WorldEnvironment = get_node(environment_node)
func _ready() -> void:
	horror_environment=horror_environment.duplicate()
	set_normal_lighting(normal_lighting)
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_L:
		set_normal_lighting(not normal_lighting)
		get_viewport().set_input_as_handled()
func set_normal_lighting(enabled: bool) -> void:
	normal_lighting=enabled
	environment.environment=normal_environment if enabled else horror_environment
	horror_lights.visible=not enabled
	for light in get_parent().get_children():
		if light is OmniLight3D: light.visible=enabled
	mode_changed.emit(enabled)
func _process(delta: float) -> void:
	if normal_lighting or flicker_amount<=0: return
	elapsed+=delta
	for name in ["CellLamp","UpperLandingLamp"]:
		var light := horror_lights.get_node(name) as Light3D
		var phase: float = 1.9 if name=="CellLamp" else 4.7
		light.light_energy=float(light.get_meta("base_energy"))* (1.0-flicker_amount*(0.5+0.5*sin(elapsed*7.4+phase)*sin(elapsed*2.3+phase)))
