extends Node
## Slow stalking gives way to a pitched-forward, uneven pursuit. No per-frame randomness.
@export_range(0.0, 1.0) var neck_twist: float = 0.12
@export_range(0.0, 0.5) var body_hunch: float = 0.22
@export var glitch_intensity: float = 1.0
@export_range(0.0, 0.2) var limp_depth: float = 0.025
var phase: float = 0.0
var elapsed: float = 0.0
var moving_blend: float = 0.0
var chase_blend: float = 0.0
var head_offset := Vector3.ZERO
var spasm_left: float = 0.0
var next_spasm: float = 1.2
var spasm_number: int = 0
var spasm: float = 0.0
var release: float = 0.0
var face_mesh: MeshInstance3D
var threat_index: int = -1
var scream_index: int = -1
func speed_factor(hunting: bool) -> float:
 return .93 + .12 * maxf(0,sin(phase)) if hunting else .82 + .16 * maxf(0,sin(phase))
func animate(delta: float, moving: bool, hunting: bool, figure: Node3D, skeleton: Skeleton3D, bones: Dictionary, rest: Dictionary) -> void:
 elapsed += delta
 moving_blend = move_toward(moving_blend,1.0 if moving else 0.0,delta*7)
 chase_blend = move_toward(chase_blend,1.0 if hunting else 0.0,delta*(7.0 if hunting else 1.8))
 phase += delta * lerpf(5.8,14.0,chase_blend) * moving_blend
 next_spasm -= delta
 spasm_left = maxf(0,spasm_left-delta)
 if next_spasm <= 0:
  spasm_number += 1
  spasm_left = .16
  next_spasm = lerpf(3.2,1.35,chase_blend) + fposmod(spasm_number*1.618,1.0)*1.1
 spasm = glitch_intensity if spasm_left>.085 else 0.0
 release = glitch_intensity if spasm_left>0 and spasm_left<=.085 else 0.0
 var stepped_phase:float = floor(phase*3.0)/3.0 if hunting else phase
 var stride := sin(stepped_phase)
 var hitch := pow(maxf(0,sin(phase+.5)),4)
 var side := -1.0 if spasm_number%2==0 else 1.0
 head_offset = Vector3(-.10-.12*chase_blend+.16*spasm-.12*release,side*.11*spasm,neck_twist*(1-.5*chase_blend)+side*.20*spasm-side*.07*release)
 figure.position.x = side*.014*spasm
 figure.position.y = -.018-hitch*limp_depth*moving_blend-.055*chase_blend
 figure.rotation.z = .025+stride*.014*moving_blend+side*.025*spasm
 if not is_instance_valid(face_mesh):
  face_mesh=figure.find_child("TheHollowVisitor_Mesh",true,false) as MeshInstance3D
  if face_mesh:
   threat_index=face_mesh.find_blend_shape_by_name("Threat")
   scream_index=face_mesh.find_blend_shape_by_name("Scream")
 if face_mesh:
  if threat_index>=0: face_mesh.set_blend_shape_value(threat_index,.12+.75*chase_blend+.10*spasm)
  if scream_index>=0: face_mesh.set_blend_shape_value(scream_index,chase_blend*(.08+.13*hitch)+.09*release)
 if not skeleton: return
 var reach := chase_blend*.10
 var poses := {
  "Head": Quaternion.from_euler(head_offset),
  "Spine": Quaternion.from_euler(Vector3(-body_hunch-.22*chase_blend-.08*release,side*.065*spasm,-.035)),
  "ArmLeft": Quaternion.from_euler(Vector3(-.08-reach+stride*.075*moving_blend,.02,.075)),
  "ArmRight": Quaternion.from_euler(Vector3(.025-reach*.65-stride*.055*moving_blend,-.02,-.06)),
  "ForearmLeft": Quaternion.from_euler(Vector3(-.04-.06*chase_blend-.04*spasm,0,.015)),
  "ForearmRight": Quaternion.from_euler(Vector3(-.03-.08*chase_blend+.03*release,0,-.015)),
  "LegLeft": Quaternion.from_euler(Vector3(stride*lerpf(.17,.28,chase_blend)*moving_blend,0,0)),
  "LegRight": Quaternion.from_euler(Vector3(-stride*lerpf(.12,.23,chase_blend)*moving_blend-.025,0,0))
 }
 for bone in poses:
  if bones.has(bone):
   var index:int=bones[bone]
   var target:Quaternion=rest[bone]*poses[bone]
   skeleton.set_bone_pose_rotation(index,skeleton.get_bone_pose_rotation(index).slerp(target,1-exp(-delta*(55 if spasm>0 or release>0 else 24))))
func apply_tracked_head(skeleton: Skeleton3D,bones: Dictionary) -> void:
 if not skeleton or not bones.has("Head"): return
 var index:int=bones["Head"]
 skeleton.set_bone_pose_rotation(index,skeleton.get_bone_pose_rotation(index)*Quaternion.from_euler(head_offset))

