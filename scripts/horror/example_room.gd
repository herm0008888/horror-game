extends Node3D

func _ready() -> void:
	$Player.acquire_flashlight()
	$Player.torch.visible = false
	$Player.pitch = -0.08
