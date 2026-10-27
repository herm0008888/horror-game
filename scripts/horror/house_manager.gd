extends Node3D
@onready var ambient: AudioStreamPlayer = $Ambience
@onready var noises: AudioStreamPlayer3D = $DistantCreak
var timer: float = 9
func _process(delta: float) -> void:
	timer -= delta
	if timer <= 0:
		timer = randf_range(12,24)
		noises.pitch_scale = randf_range(0.5,0.8)
		noises.play()
func _exit_tree() -> void:
	ambient.stop()
	noises.stop()
