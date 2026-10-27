extends Node3D
@export var starts_equipped: bool = false
var equipped := false
var switched_on := false
@onready var held_model: Node3D = $HeldModel
@onready var beam: SpotLight3D = $Beam
@onready var spill: SpotLight3D = $Spill
func _ready() -> void:
	if starts_equipped: acquire()
	else: set_switched_on(false)
func acquire() -> void:
	equipped=true
	held_model.visible=true
	set_switched_on(true)
func set_switched_on(enabled: bool) -> void:
	switched_on=enabled and equipped
	beam.visible=switched_on
	spill.visible=switched_on
func _unhandled_input(event: InputEvent) -> void:
	if equipped and (event.is_action_pressed("flashlight") or (event is InputEventKey and event.pressed and event.physical_keycode==KEY_F)) and not event.is_echo():
		set_switched_on(not switched_on)
		get_viewport().set_input_as_handled()
