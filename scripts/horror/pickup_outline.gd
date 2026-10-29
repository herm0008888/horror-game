extends Node
var target:Node
var originals:Dictionary={}
var outline:ShaderMaterial
func _ready():
 var shader=Shader.new()
 shader.code="shader_type spatial; render_mode unshaded, cull_front; void vertex(){VERTEX+=NORMAL*0.004;} void fragment(){ALBEDO=vec3(1.0); }"
 outline=ShaderMaterial.new();outline.shader=shader
func clear():
 for mesh in originals:
  if is_instance_valid(mesh):mesh.material_overlay=originals[mesh]
 originals.clear();target=null
func mark(node:Node):
 if node is MeshInstance3D and node.mesh:
  originals[node]=node.material_overlay;node.material_overlay=outline
 for child in node.get_children():mark(child)
func _physics_process(_delta):
 var p=get_parent()
 if p.caught:
  clear();return
 var exclude:Array[RID]=p.get_node("ToolController").carry_exclusions() if p.has_node("ToolController") else [p.get_rid()]

 var ray=PhysicsRayQueryParameters3D.create(p.camera.global_position,p.camera.global_position-p.camera.global_basis.z*2.6,49,exclude)
 ray.collide_with_areas=true
 ray.hit_from_inside=true
 var hit=p.get_world_3d().direct_space_state.intersect_ray(ray)
 var next:Node=null
 if not hit.is_empty():
  var body=hit.collider
  var service=get_tree().get_first_node_in_group("prop_interaction")
  var prop: Node3D=service.resolve(body) if service else null
  if prop:
   if service.should_highlight(prop):next=prop
  elif body.get_script():
   var path: String=body.get_script().resource_path
   if path.ends_with("sledge_pickup.gd") or path.ends_with("flashlight_pickup.gd"):next=body
 if next==target:return
 clear();target=next
 if target:mark(target)
func _exit_tree():clear()
