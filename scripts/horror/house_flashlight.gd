extends Node3D
@export var starts_equipped: bool = false
var equipped := false
var switched_on := false
var range_timer:=0.0
var target_range:=12.0
@onready var held_model: Node3D = $HeldModel
@onready var beam: SpotLight3D = $Beam
@onready var spill: SpotLight3D = $Spill
func _ready() -> void:
	if starts_equipped: acquire()
	else: set_switched_on(false)
func acquire(enabled: bool=true) -> void:
	equipped=true
	held_model.visible=true
	set_switched_on(enabled)
func release() -> bool:
	var was_on:=switched_on
	equipped=false
	held_model.visible=false
	set_switched_on(false)
	return was_on
func set_switched_on(enabled: bool) -> void:
	switched_on=enabled and equipped
	beam.visible=switched_on
	spill.visible=switched_on
func _unhandled_input(event: InputEvent) -> void:
	if equipped and (event.is_action_pressed("flashlight") or (event is InputEventKey and event.pressed and event.physical_keycode==KEY_F)) and not event.is_echo():
		set_switched_on(not switched_on)
		get_viewport().set_input_as_handled()
func _physics_process(delta: float):
	if not switched_on:return
	range_timer-=delta
	if range_timer<=0:
		range_timer=.12
		update_visible_range()
	beam.spot_range=lerpf(beam.spot_range,target_range,1.0-exp(-delta*10.0))
func update_visible_range():
	var start=beam.global_position
	var finish=start-beam.global_basis.z*12.0
	var excluded: Array[RID]=[]
	var player=get_parent().get_parent()
	if player is CollisionObject3D:excluded.append(player.get_rid())
	target_range=12.0
	# Do not submit shadow geometry far behind the opaque wall we face.
	# Furniture is skipped so a nearby chair cannot shorten the whole beam.
	for i in range(12):
		var query=PhysicsRayQueryParameters3D.create(start,finish,1,excluded)
		query.hit_from_inside=true
		var hit=get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty():return
		var body=hit.collider
		var mesh=body.get_node_or_null("Mesh") as MeshInstance3D
		if (mesh and mesh.has_meta("house_surface")) or body.is_in_group("weak_walls"):
			target_range=clampf(start.distance_to(hit.position)+2.8,5.0,12.0)
			return
		excluded.append(body.get_rid())
