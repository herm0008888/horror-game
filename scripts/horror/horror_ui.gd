extends CanvasLayer
## Screen-only atmosphere: no camera movement, UV distortion, or world material changes.
@export_node_path("Node3D") var lighting_path: NodePath = NodePath("../Lighting")
@export_node_path("CharacterBody3D") var player_path: NodePath = NodePath("../Player")
@export_range(0.0,0.5) var vignette_strength: float = 0.22
@export_range(0.0,0.05) var grain_strength: float = 0.015
@export_range(0.0,0.1) var pulse_strength: float = 0.025
@export var rare_interference: bool = true
var effects_enabled := true
var elapsed := 0.0
var tension := 0.25
var shock := 0.0
var previous_vertical_speed := 0.0
var next_interference := 10.0
var interference_left := 0.0
var disturbance_number := 0
@onready var overlay: ColorRect = $Overlay
@onready var effect_material: ShaderMaterial = overlay.material
@onready var player: CharacterBody3D = get_node_or_null(player_path)
func _ready() -> void:
	effect_material=effect_material.duplicate()
	overlay.material=effect_material
	effect_material.set_shader_parameter("vignette_strength",vignette_strength)
	effect_material.set_shader_parameter("grain_strength",grain_strength)
	effect_material.set_shader_parameter("pulse_strength",pulse_strength)
	var lighting := get_node_or_null(lighting_path)
	if lighting and lighting.has_signal("mode_changed"):
		lighting.mode_changed.connect(_on_lighting_mode_changed)
		_on_lighting_mode_changed(lighting.normal_lighting)
func _on_lighting_mode_changed(normal: bool) -> void:
	effects_enabled=not normal
	overlay.visible=effects_enabled
	set_process(effects_enabled)
func _process(delta: float) -> void:
	elapsed+=delta
	shock=move_toward(shock,0.0,delta*1.4)
	if player:
		var target_tension := 0.55 if player.global_position.y < -1.0 else 0.18
		tension=lerpf(tension,target_tension,1.0-exp(-delta*1.5))
		if player.is_on_floor() and previous_vertical_speed < -5.0: shock=0.65
		previous_vertical_speed=player.velocity.y
	interference_left=maxf(0.0,interference_left-delta)
	if rare_interference and elapsed>=next_interference:
		disturbance_number+=1
		interference_left=0.09
		next_interference=elapsed+11.0+fposmod(float(disturbance_number)*2.718,6.0)
		effect_material.set_shader_parameter("interference_y",0.22+fposmod(float(disturbance_number)*0.381,0.56))
	effect_material.set_shader_parameter("tension",tension)
	effect_material.set_shader_parameter("shock",shock)
	effect_material.set_shader_parameter("interference",interference_left/0.09 if rare_interference else 0.0)
