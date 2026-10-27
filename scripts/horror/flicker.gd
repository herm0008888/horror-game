extends OmniLight3D
@export var instability: float = 0.3
var baseline: float
var time: float = 0
func _ready() -> void:
	baseline = light_energy
	time = randf() * 100.0
func _process(delta: float) -> void:
	time += delta
	var failure := sin(time * 0.81) > 0.92
	var brightness := 0.24 + absf(sin(time * 47.0)) * 0.36 if failure else 0.96 + sin(time * 5.0) * 0.04
	light_energy = baseline * lerpf(1.0, brightness, instability)
