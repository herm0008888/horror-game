extends Node3D
var intro_done := false
var dropped := false
var elapsed := 0.0
var climbing := false
var carrying_plank := false
var bridge_placed := false
var hatch_tween: Tween
@onready var player: CharacterBody3D = $Player
@onready var status: Label = $HUD/Status
@onready var hinge: Node3D = $EntranceHatch
@onready var hatch_collision: CollisionShape3D = $EntranceHatch/Panel/Collision
@onready var ladder_cover: CollisionShape3D = $LadderCover/Collision
@onready var plank: StaticBody3D = $BridgePlank
@onready var plank_collision: CollisionShape3D = $BridgePlank/Collision
const LOWER := Vector3(10.6,-3.39,2.6)
const UPPER := Vector3(11.6,0.02,2.6)
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_T:
		restart_intro()
	if event.is_action_pressed("interact") and ladder_near() and not climbing:
		climb_ladder()
	elif event.is_action_pressed("interact") and intro_done and not climbing:
		if carrying_plank and near_trap():
			place_plank()
		elif not carrying_plank and not bridge_placed and player.global_position.distance_to(plank.global_position)<1.8:
			player.release_hand_items()
			carrying_plank=true
			plank.visible=false
			plank_collision.set_deferred("disabled",true)
func ladder_near() -> bool:
	return player.global_position.distance_to(LOWER)<1.7 or player.global_position.distance_to(UPPER)<1.6
func drop_carried_plank() -> void:
	if not carrying_plank: return
	var desired:=player.global_position-player.global_basis.z*0.8
	var ray:=PhysicsRayQueryParameters3D.create(desired+Vector3.UP,desired-Vector3.UP*2.0,1,[player.get_rid()])
	var hit:=get_world_3d().direct_space_state.intersect_ray(ray)
	if not hit.is_empty(): desired.y=hit.position.y+0.05
	else: desired=player.global_position+Vector3.UP*0.05
	carrying_plank=false
	plank.global_position=desired
	plank.visible=true
	plank_collision.set_deferred("disabled",false)
func near_trap() -> bool:
	return absf(player.position.x-6)<1.2 and absf(player.position.z-14)<1.9 and player.position.y>-0.5 and player.position.y<1.0
func place_plank() -> void:
	carrying_plank=false
	bridge_placed=true
	plank.position=Vector3(6,0,14)
	plank.visible=true
	plank_collision.set_deferred("disabled",false)
func restart_intro() -> void:
	if climbing: return
	if hatch_tween and hatch_tween.is_running(): hatch_tween.kill()
	intro_done=false
	dropped=false
	elapsed=0
	carrying_plank=false
	bridge_placed=false
	plank.position=Vector3(9,0,10)
	plank.visible=true
	plank_collision.set_deferred("disabled",false)
	hinge.rotation.x=0
	hatch_collision.set_deferred("disabled",false)
	player.position=Vector3(6,0.08,14)
	player.start=player.position
	player.velocity=Vector3.ZERO
func _process(delta: float) -> void:
	elapsed+=delta
	if not intro_done and not dropped and elapsed>0.12 and absf(player.position.x-6)<0.78 and absf(player.position.z-14)<0.78 and player.position.y>-0.2:
		dropped=true
		hatch_collision.set_deferred("disabled",true)
		hatch_tween=create_tween()
		hatch_tween.tween_property(hinge,"rotation:x",deg_to_rad(95),0.2)
	if dropped and not intro_done and player.position.y < -3.1:
		intro_done=true
		player.start=Vector3(6,-3.3,14)
	if climbing:
		status.text="Klatrer …"
	elif ladder_near():
		status.text="E · Bruk den skjulte stigen"
	elif carrying_plank and near_trap():
		status.text="E · Legg planken over fella"
	elif intro_done and not carrying_plank and not bridge_placed and player.global_position.distance_to(plank.global_position)<1.8:
		status.text="E · Plukk opp planken"
	elif not intro_done:
		status.text="Du søker ly. Gulvet knirker under deg …"
	elif player.position.y < -1 and player.position.x>4 and player.position.x<8 and player.position.z>12:
		status.text="Porten er låst. Slegga ligger utenfor sprinklene. Finn det sprukne murverket."
	else:
		status.text="Bærer planke · Finn fella ved ytterdøra" if carrying_plank else ("Kjeller" if player.position.y < -1 else ("Første etasje" if player.position.y<2 else "Andre etasje"))
func climb_ladder() -> void:
	if climbing: return
	climbing=true
	var going_up := player.position.y < -1
	player.set_physics_process(false)
	player.velocity=Vector3.ZERO
	ladder_cover.set_deferred("disabled",true)
	var tween := create_tween()
	if going_up:
		tween.tween_property(player,"position",LOWER,0.25)
		tween.tween_property(player,"position",Vector3(10.6,0.08,2.6),1.2)
		tween.tween_property(player,"position",UPPER,0.3)
	else:
		tween.tween_property(player,"position",Vector3(10.6,0.08,2.6),0.3)
		tween.tween_property(player,"position",LOWER,1.2)
	await tween.finished
	ladder_cover.set_deferred("disabled",false)
	player.set_physics_process(true)
	climbing=false
