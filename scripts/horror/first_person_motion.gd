extends Node
@export_node_path("CharacterBody3D") var player_path: NodePath=NodePath("../..")
@export var bob_height: float=.018
@export var bob_width: float=.010
@export var lean_distance: float=.16
@export var lean_angle: float=4.0
var player: CharacterBody3D
var camera: Camera3D
var phase:=0.0
var elapsed:=0.0
var lean:=0.0
var turn_sway:=0.0
var landing:=0.0
var previous_velocity:=Vector3.ZERO
var was_grounded:=true
var base_fov:=75.0
var lean_target:=0.0
var held_model: Node3D
var held_rest:=Transform3D.IDENTITY
func _ready():
 player=get_node(player_path);camera=player.get_node("Camera");base_fov=camera.fov
 held_model=player.get_node_or_null("Camera/FlashlightRig/HeldModel")
 if held_model:held_rest=held_model.transform
func _input(event):
 if event is InputEventMouseMotion and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED and not player.caught:
  turn_sway=clampf(turn_sway-event.relative.x*.00032,-.025,.025)
func _process(delta: float):
 if not is_instance_valid(player) or player.caught:return
 elapsed+=delta
 var speed:=Vector2(player.velocity.x,player.velocity.z).length()
 var grounded:=player.is_on_floor()
 var movement:=clampf(speed/3.0,0.0,1.0) if grounded else 0.0
 phase+=delta*speed*4.2
 var local_velocity:=player.global_basis.inverse()*player.velocity
 var acceleration: Vector3=(player.velocity-previous_velocity)/maxf(delta,.001)
 previous_velocity=player.velocity
 if grounded and not was_grounded:landing=clampf(-player.velocity.y*.002+absf(acceleration.y)*.0001,.008,.045)
 was_grounded=grounded
 landing=move_toward(landing,0,delta*.18)
 var goal_lean:=lean_target
 lean=lerpf(lean,goal_lean,1-exp(-delta*8))
 turn_sway=lerpf(turn_sway,0.0,1-exp(-delta*10))
 var breath:=sin(elapsed*1.4)*.0025
 var offset:=Vector3(sin(phase*.5)*bob_width*movement+lean*lean_distance,absf(sin(phase))*bob_height*movement+breath-landing,0)
 offset.z=clampf((player.global_basis.inverse()*acceleration).z*.00045,-.014,.014)
 var target_height: float=.8 if player.crouched else 1.6
 camera.position=camera.position.lerp(Vector3(offset.x,target_height+offset.y,offset.z),1-exp(-delta*13))
 var roll: float=-deg_to_rad(lean_angle)*lean-clampf(local_velocity.x/3.0,-1,1)*.014+turn_sway*.45
 var pitch: float=player.pitch+sin(phase)*movement*.0025+landing*.45
 camera.rotation.x=lerp_angle(camera.rotation.x,pitch,1-exp(-delta*24))
 camera.rotation.y=lerp_angle(camera.rotation.y,turn_sway,1-exp(-delta*18))
 camera.rotation.z=lerp_angle(camera.rotation.z,roll,1-exp(-delta*10))
 camera.fov=lerpf(camera.fov,base_fov+movement*.9-(1.2 if player.crouched else 0),1-exp(-delta*5))
 if held_model and held_model.visible:
  held_model.position=held_rest.origin+Vector3(-turn_sway*.2,sin(phase)*movement*.006+breath*.5,0)
  held_model.rotation=held_rest.basis.get_euler()+Vector3(sin(phase)*movement*.008,-turn_sway*1.4,roll*.4)

func _physics_process(_delta: float):
 if not is_instance_valid(player) or player.caught:return
 var manual: float=float(Input.is_physical_key_pressed(KEY_C))-float(Input.is_physical_key_pressed(KEY_Z))
 lean_target=manual
 if absf(lean_target)>.01:
  var start:=player.global_position+Vector3.UP*(.8 if player.crouched else 1.6)
  var query:=PhysicsRayQueryParameters3D.create(start,start+player.global_basis.x*lean_target*(lean_distance+.12),1,[player.get_rid()])
  if not player.get_world_3d().direct_space_state.intersect_ray(query).is_empty():lean_target=0.0
