extends Node
## Adjust only the 3D resolution; the speedometer stays at native resolution.
@export_range(0.5, 1.0) var minimum_scale: float = 0.65
@export_range(0.5, 1.0) var maximum_scale: float = 1.0
@export var target_fps: float = 50.0
var elapsed: float = 0.0
var frames: int = 0
var warmup: float = 3.0

func _process(delta: float) -> void:
	if warmup > 0.0:
		warmup -= delta
		return
	elapsed += delta
	frames += 1
	if elapsed < 1.5: return
	var fps := frames / elapsed
	var viewport := get_viewport()
	if fps < target_fps - 5.0:
		viewport.scaling_3d_scale = maxf(minimum_scale, viewport.scaling_3d_scale - 0.05)
	elif fps > target_fps + 9.0:
		viewport.scaling_3d_scale = minf(maximum_scale, viewport.scaling_3d_scale + 0.025)
	elapsed = 0.0
	frames = 0
