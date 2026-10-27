extends Node3D
@export var situations: Array[PackedScene] = []
var current_situation: int = 0
func _ready() -> void: call_deferred("apply_situation")
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		if key >= KEY_1 and key <= KEY_5: switch_situation(key-KEY_1)
func switch_situation(index: int) -> void:
	if index < 0 or index >= situations.size(): return
	get_tree().set_meta("creature_situation",index)
	get_tree().call_deferred("reload_current_scene")
func apply_situation() -> void:
	current_situation = clampi(int(get_tree().get_meta("creature_situation",0)),0,situations.size()-1)
	var setup := situations[current_situation].instantiate() as Node3D
	add_child(setup)
	var player: CharacterBody3D = $Player
	var enemy: CharacterBody3D = $Visitation
	player.global_transform = setup.get_node("PlayerSpawn").global_transform
	player.spawn = player.global_transform
	enemy.global_position = setup.get_node("EnemySpawn").global_position
	enemy.figure.rotation.y = setup.get_node("EnemySpawn").rotation.y
	enemy.route_path.clear()
	enemy.repath = 0
	if setup.get_meta("alerted",false):
		enemy.has_seen_player = true
		enemy.state = "CHASE"
		enemy.hunt = 20.0
		enemy.last_seen = player.global_position
	enemy.corner.cooldown = 0 if current_situation == 1 else 2.0
	if setup.get_meta("equipped",false):
		player.acquire_flashlight()
		$FlashlightPickup.queue_free()
	else:
		$FlashlightPickup.position = player.position + player.global_basis * Vector3(-0.9,0.77,-1.7)
		$Geometry/PickupPlinth.position = $FlashlightPickup.position-Vector3(0,0.46,0)
	var dark: bool = setup.get_meta("dark",false)
	$KeyLight.light_energy = 0.025 if dark else 0.45
	$FillLight.light_energy = 0.06 if dark else 1.1
	$Environment.environment = $Environment.environment.duplicate()
	$Environment.environment.ambient_light_energy = 0.045 if dark else 0.35
	for lamp in $LabLighting.get_children():
		if lamp is OmniLight3D: lamp.light_energy = 0.03 if dark else 1.2
