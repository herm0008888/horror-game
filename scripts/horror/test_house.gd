extends Node3D
@export var room_regions: Array[Dictionary] = []
@onready var player: CharacterBody3D = $Player
@onready var location: Label = $HUD/Location
@onready var prompt_label: Label = $HUD/Prompt
@onready var overview: PanelContainer = $HUD/Overview
var survey_light := false
var startup_time: float = 0.0

func _ready() -> void:
	overview.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_M: overview.visible = not overview.visible
		if event.physical_keycode == KEY_L:
			survey_light = not survey_light
			$Environment.environment.ambient_light_energy = 0.8 if survey_light else 0.3

func _process(delta: float) -> void:
	startup_time += delta
	var position := player.global_position
	var title := "Trapperom"
	var floor_name := "Hovedetasje" if position.y > -1.4 and position.y < 2.0 else ("Kjeller" if position.y <= -1.4 else "Loftsetasje")
	for region in room_regions:
		if (region.bounds as AABB).has_point(position + Vector3.UP * 0.1):
			title = region.title
			break
	location.text = "%s  /  %s" % [floor_name.to_upper(), title]
	if is_instance_valid(player.look_target): prompt_label.text = player.look_target.prompt()
	elif startup_time < 8.0: prompt_label.text = "M  ·  Oversikt over huset"
	else: prompt_label.text = ""
