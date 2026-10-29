extends Node
@export_node_path("CharacterBody3D") var player_path: NodePath=NodePath("../..")
@export var large_hold_time: float=.95
@export var very_large_hold_time: float=1.2
var player: CharacterBody3D
var target: Node3D
var tap_action: Node
var elapsed:=0.0
var duration:=0.0
var holding:=false
func _ready():player=get_node(player_path)
func ring(value: float):get_tree().call_group("pickup_progress","set_progress",value)
func cancel():
 holding=false;target=null;tap_action=null;elapsed=0.0;ring(0.0)
func hit_target() -> Dictionary:
 var query:=PhysicsRayQueryParameters3D.create(player.camera.global_position,player.camera.global_position-player.camera.global_basis.z*2.6,49,player.get_node("ToolController").carry_exclusions())
 query.collide_with_areas=true;query.hit_from_inside=true
 return player.get_world_3d().direct_space_state.intersect_ray(query)
func begin():
 cancel()
 var service=get_tree().get_first_node_in_group("prop_interaction")
 var hit:=hit_target()
 if hit.is_empty():return
 var object: Node=hit.collider
 var prop: Node3D=service.resolve(object) if service else null
 var special:=false
 if object.get_script():
  var path: String=object.get_script().resource_path
  special=path.ends_with("flashlight_pickup.gd") or path.ends_with("sledge_pickup.gd")
 if object.has_method("interact") and (not prop or special):object.interact();return
 if not prop:
  var parent:=object.get_parent()
  while parent and parent!=player.get_parent():
   if parent.has_method("interact"):parent.interact();return
   parent=parent.get_parent()
  return
 target=prop
 if object.has_method("set_open"):tap_action=object
 var size: Vector3=service.world_bounds(prop).size
 var maximum: float=maxf(size.x,maxf(size.y,size.z))
 duration=very_large_hold_time if maximum>1.6 else large_hold_time
 if maximum<=service.small_item_size and not is_instance_valid(tap_action):complete();return
 holding=true
func complete():
 var prop:=target
 cancel()
 if not is_instance_valid(prop):return
 var service=get_tree().get_first_node_in_group("prop_interaction")
 if service:
  var body: RigidBody3D=service.make_body(prop)
  if body:player.get_node("ToolController").grab(body)
func _unhandled_input(event):
 if event.is_action_pressed("release_mouse"):
  cancel();return
 if player.caught:cancel();return
 if event.is_action_pressed("interact") and not event.is_echo():
  begin();get_viewport().set_input_as_handled()
 elif event.is_action_released("interact"):
  var action:=tap_action
  cancel()
  if is_instance_valid(action):action.interact()
  get_viewport().set_input_as_handled()
func advance(delta: float):
 if not holding:return
 if player.caught or not is_instance_valid(target):cancel();return
 var hit:=hit_target()
 var service=get_tree().get_first_node_in_group("prop_interaction")
 if hit.is_empty() or not service or service.resolve(hit.collider)!=target:cancel();return
 elapsed+=delta
 if elapsed>=duration:complete()
 else:ring(elapsed/duration)
func _physics_process(delta: float):advance(delta)
func _exit_tree():
 if is_inside_tree():ring(0.0)

func _notification(what):
 if what==NOTIFICATION_APPLICATION_FOCUS_OUT and is_inside_tree():cancel()
