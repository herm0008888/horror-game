extends Node3D
const SWING_DURATION:=0.28
const HIT_TIME:=0.09
const REST_POSITION:=Vector3(.56,-.43,-.67)
const REST_ROTATION:=Vector3(-9,-22,18)
var player: CharacterBody3D
var held: Node3D
var hammer_equipped:=false
var swing_left:=0.0
var hit_done:=false
var swing_hit: Dictionary={}
var target_pending:=false
const HEAD_CONTACT:=Vector3(.125,.56,0)
var grabbed: RigidBody3D
var grabbed_center:=Vector3.ZERO
var grabbed_relative_rotation:=Basis.IDENTITY
var grabbed_distance:=1.0
var grabbed_radius:=0.2
var carry_phase:=0.0
var grabbed_large:=false
var grabbed_gravity:=1.0
var grabbed_linear_damp:=0.0
var grabbed_angular_damp:=0.0
var grabbed_colliders: Array[PhysicsBody3D]=[]
var impact_sound: AudioStreamPlayer3D
var hint: Label
func _ready():
	player=get_parent()
	impact_sound=AudioStreamPlayer3D.new()
	add_child(impact_sound)
	var audio=AudioStreamWAV.new()
	audio.format=AudioStreamWAV.FORMAT_16_BITS
	audio.mix_rate=22050
	var bytes=PackedByteArray()
	bytes.resize(4410*2)
	var rng=RandomNumberGenerator.new()
	rng.seed=42
	for i in range(4410):
		var t=i/22050.0
		var v=(sin(t*TAU*78)*.55+rng.randf_range(-1,1)*.28)*exp(-t*23)
		bytes.encode_s16(i*2,int(v*28000))
	audio.data=bytes
	impact_sound.stream=audio
	impact_sound.volume_db=-9
	var ui=CanvasLayer.new()
	add_child(ui)
	hint=Label.new()
	hint.position=Vector2(24,650)
	hint.add_theme_font_size_override("font_size",15)
	ui.add_child(hint)
func drop_held() -> bool:
	if is_instance_valid(grabbed):
		drop_grabbed()
		return true
	if not hammer_equipped: return false
	var pickup=load("res://scenes/horror/sledge_pickup.tscn").instantiate()
	player.get_parent().add_child(pickup)
	pickup.global_position=player.camera.global_position-player.camera.global_basis.z*.7
	pickup.freeze=false
	pickup.linear_velocity=player.velocity-player.camera.global_basis.z*.8
	pickup.add_collision_exception_with(player)
	get_tree().create_timer(.5).timeout.connect(func():
		if is_instance_valid(pickup): pickup.remove_collision_exception_with(player))
	if is_instance_valid(held): held.queue_free()
	held=null
	swing_left=0.0
	hit_done=false
	hammer_equipped=false
	swing_hit={}
	target_pending=false
	return true
func equip(model: Node3D):
	player.release_hand_items()
	held=Node3D.new()
	held.name="SledgeGrip"
	player.camera.add_child(held)
	held.add_child(model)
	# Grip near the handle's lower end; rotate around the hand, not the head.
	model.position=Vector3(0,.46,0)
	model.rotation=Vector3.ZERO
	held.position=REST_POSITION
	held.rotation_degrees=REST_ROTATION
	hammer_equipped=true
	swing_left=0.0
	hit_done=false
func grab(body: RigidBody3D):
	var service=get_tree().get_first_node_in_group("prop_interaction")
	var box: AABB=service.world_bounds(body) if service else AABB(body.global_position-Vector3.ONE*.15,Vector3.ONE*.3)
	var near: Vector3=player.camera.global_position.clamp(box.position,box.end)
	if near.distance_to(player.camera.global_position)>2.8:return
	if grabbed==body:
		drop_grabbed();return
	player.release_hand_items()
	grabbed=body
	get_tree().call_group("dynamic_navigation","request_update")
	grabbed_center=body.to_local(box.get_center())
	grabbed_radius=maxf(box.size.x,maxf(box.size.y,box.size.z))*.5
	grabbed_large=grabbed_radius>.325
	grabbed_distance=maxf(1.0,grabbed_radius+1.0) if grabbed_large else .9+grabbed_radius
	var reference: Basis=player.global_basis if grabbed_large else player.camera.global_basis
	grabbed_relative_rotation=reference.orthonormalized().inverse()*body.global_basis.orthonormalized()
	grabbed_gravity=body.gravity_scale;grabbed_linear_damp=body.linear_damp;grabbed_angular_damp=body.angular_damp
	body.gravity_scale=0.0;body.linear_damp=3.0;body.angular_damp=5.0
	body.freeze=false;body.sleeping=false;body.continuous_cd=true
	grabbed_colliders=service.body_colliders(body) if service else [body]
	for collider in grabbed_colliders:collider.add_collision_exception_with(player)
func drop_grabbed():
	if not is_instance_valid(grabbed):
		grabbed=null;return
	if grabbed_large:get_tree().call_group("dynamic_navigation","request_update")
	grabbed.freeze=false;grabbed.sleeping=false
	grabbed.gravity_scale=grabbed_gravity
	grabbed.linear_damp=grabbed_linear_damp;grabbed.angular_damp=grabbed_angular_damp
	grabbed.linear_velocity=player.velocity-player.camera.global_basis.z*.6
	var colliders:=grabbed_colliders.duplicate()
	grabbed=null;grabbed_colliders.clear()
	get_tree().create_timer(.5).timeout.connect(func():
		for collider in colliders:
			if is_instance_valid(collider) and is_instance_valid(player):collider.remove_collision_exception_with(player))
func carry_exclusions() -> Array[RID]:
	var result: Array[RID]=[player.get_rid()]
	for collider in grabbed_colliders:
		if is_instance_valid(collider):result.append(collider.get_rid())
	return result
func move_grabbed(delta: float):
	var start: Vector3=player.camera.global_position
	var forward: Vector3=-player.camera.global_basis.z
	carry_phase+=delta*Vector2(player.velocity.x,player.velocity.z).length()*3.0
	var sway:=sin(carry_phase)*(.004 if grabbed_large else .009)
	var target: Vector3=start+forward*grabbed_distance-Vector3.UP*(.28 if grabbed_large else .12)+player.camera.global_basis.x*sway
	var query:=PhysicsRayQueryParameters3D.create(start,target,1,carry_exclusions())
	var hit:=player.get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var available:=maxf(.55,start.distance_to(hit.position)-grabbed_radius-.08)
		target=start+forward*minf(grabbed_distance,available)-Vector3.UP*(.28 if grabbed_large else .12)
	var reference: Basis=player.global_basis if grabbed_large else player.camera.global_basis
	var desired_basis:=reference.orthonormalized()*grabbed_relative_rotation
	var origin: Vector3=target-desired_basis*grabbed_center
	# Drive velocity instead of teleporting/freeze: walls and other props still collide.
	var desired_velocity: Vector3=((origin-grabbed.global_position)*10.0+player.velocity).limit_length(7.0 if grabbed_large else 10.0)
	grabbed.linear_velocity=grabbed.linear_velocity.lerp(desired_velocity,1-exp(-delta*(10.0 if grabbed_large else 16.0)))
	var rotation_error:=desired_basis.get_rotation_quaternion()*grabbed.global_basis.orthonormalized().get_rotation_quaternion().inverse()
	if rotation_error.w<0:rotation_error=-rotation_error
	var desired_spin:=rotation_error.get_axis()*minf(rotation_error.get_angle()*10.0,7.0)
	grabbed.angular_velocity=grabbed.angular_velocity.lerp(desired_spin,1-exp(-delta*12.0))
	grabbed.sleeping=false
	if grabbed.global_position.distance_to(origin)>grabbed_distance+2.0:drop_grabbed()
func on_capture():
	if is_instance_valid(held): held.hide()
	drop_grabbed()
	hint.hide()
func _unhandled_input(event):
	if player.caught: return
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed and hammer_equipped and swing_left<=0:
		begin_swing()
		get_viewport().set_input_as_handled()
	if event is InputEventKey and event.pressed and event.physical_keycode==KEY_G:
		drop_grabbed()
func begin_swing():
	if not hammer_equipped or swing_left>0: return
	swing_left=SWING_DURATION
	hit_done=false
	swing_hit={}
	target_pending=true
func find_target() -> Dictionary:
	var start=player.camera.global_position
	var query=PhysicsRayQueryParameters3D.create(start,start-player.camera.global_basis.z*1.8,17,[player.get_rid()])
	return player.get_world_3d().direct_space_state.intersect_ray(query)
func impact_pose() -> Transform3D:
	var target=Vector3(0,0,-1.15)
	var normal=Vector3.BACK
	if not swing_hit.is_empty():
		target=player.camera.to_local(swing_hit.position)
		normal=(player.camera.global_basis.inverse()*swing_hit.normal).normalized()
	var x=-normal
	var y=Vector3(-.65,.76,0)
	y=(y-x*y.dot(x)).normalized()
	if y.length_squared()<.1:y=Vector3.RIGHT.cross(x).normalized()
	var basis=Basis(x,y,x.cross(y).normalized()).orthonormalized()
	# The metal striking face, not the grip or crosshair, ends at the wall.
	return Transform3D(basis,target-basis*HEAD_CONTACT)
func animate_swing(elapsed: float):
	if not is_instance_valid(held): return
	var rest=Transform3D(Basis.from_euler(REST_ROTATION*PI/180.0),REST_POSITION)
	var wind=Transform3D(Basis.from_euler(Vector3(22,-28,32)*PI/180.0),Vector3(.64,-.30,-.49))
	var impact=impact_pose()
	if elapsed<.035:
		held.transform=rest.interpolate_with(wind,elapsed/.035)
	elif elapsed<HIT_TIME:
		var t=(elapsed-.035)/(HIT_TIME-.035)
		held.transform=wind.interpolate_with(impact,t*t)
	else:
		var t=clampf((elapsed-HIT_TIME)/(SWING_DURATION-HIT_TIME),0,1)
		held.transform=impact.interpolate_with(rest,t*t*(3-2*t))
func strike():
	var direction=-player.camera.global_basis.z
	var hit=find_target()
	if swing_left>0 and not swing_hit.is_empty():
		var start=player.camera.global_position
		var toward: Vector3=swing_hit.position-start
		if toward.length()>1.85:return
		direction=toward.normalized()
		var query=PhysicsRayQueryParameters3D.create(start,swing_hit.position+direction*.03,17,[player.get_rid()])
		hit=player.get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty() or hit.collider!=swing_hit.collider:return
	if hit.is_empty(): return
	impact_sound.global_position=hit.position
	impact_sound.play()
	if hit.collider.has_method("strike"): hit.collider.strike(direction)
	elif hit.collider is RigidBody3D:
		hit.collider.sleeping=false
		hit.collider.apply_impulse(direction*3,hit.position-hit.collider.global_position)
	# The noise attracts investigation without revealing subsequent movement.
	get_tree().call_group("horror_listener","hear_noise",hit.position,12.0)
func _physics_process(delta):
	if player.caught:
		on_capture()
		return
	hint.visible=(hammer_equipped or is_instance_valid(grabbed)) and not player.caught
	hint.text="Slegge · Venstreklikk slå · Q slipp" if hammer_equipped else "Q / G · Slipp gjenstand"
	if is_instance_valid(grabbed):move_grabbed(delta)
	if swing_left<=0: return
	if target_pending:
		swing_hit=find_target()
		target_pending=false
	swing_left=maxf(0,swing_left-delta)
	var elapsed=SWING_DURATION-swing_left
	animate_swing(elapsed)
	if elapsed>=HIT_TIME and not hit_done:
		animate_swing(HIT_TIME)
		hit_done=true
		strike()
