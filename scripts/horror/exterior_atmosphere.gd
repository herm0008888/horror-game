extends Node3D
## Camera-based transition also works with the editable cinematic cameras.
@export var forest_fog_end: float=64.0
@export var forest_fog_begin: float=12.0
@export var forest_ambient: float=.34
var base: Dictionary={}
var environment: Environment
var mix_amount:=0.0
func _process(delta: float):
 var camera:=get_viewport().get_camera_3d()
 var world:=get_parent().get_node_or_null("Environment") as WorldEnvironment
 if not camera or not world or not world.environment:return
 if environment!=world.environment:
  environment=world.environment
  base={"begin":environment.fog_depth_begin,"end":environment.fog_depth_end,"color":environment.fog_light_color,"density":environment.fog_density,"ambient":environment.ambient_light_energy}
 var p:=camera.global_position
 var outside:=maxf(maxf(-p.x,p.x-16.0),maxf(-p.z,p.z-16.0))
 mix_amount=lerpf(mix_amount,smoothstep(-.1,2.5,outside),1.0-exp(-delta*2.5))
 var lighting=get_parent().get_node_or_null("Lighting")
 if lighting and lighting.normal_lighting:
  $ColdMoon.visible=false
  return
 environment.fog_depth_begin=lerpf(base.begin,forest_fog_begin,mix_amount)
 environment.fog_depth_end=lerpf(base.end,forest_fog_end,mix_amount)
 environment.fog_light_color=base.color.lerp(Color(.06,.085,.10),mix_amount)
 environment.fog_density=lerpf(base.density,.72,mix_amount)
 environment.ambient_light_energy=lerpf(base.ambient,forest_ambient,mix_amount)
 $ColdMoon.visible=mix_amount>.02
