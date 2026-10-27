extends ColorRect
var caught := false
func _process(_delta: float) -> void:
	material.set_shader_parameter("panic", 1.0 if caught else 0.0)
	material.set_shader_parameter("clock", Time.get_ticks_msec() / 1000.0)
func set_caught() -> void: caught = true
