shader_type spatial;
uniform sampler2D surface_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D detail_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D roughness_texture : filter_linear_mipmap, repeat_enable;
uniform vec4 tint : source_color = vec4(1.0);
uniform bool use_texture = true;
uniform bool use_normal = false;
uniform bool use_roughness = false;
uniform bool body_mode = false;
uniform float normal_strength = 0.4;
uniform float normal_tiling = 1.0;
uniform float roughness_value = 0.85;
uniform float roughness_min = 0.0;
uniform float specular_value = 0.5;
uniform float coat = 0.45;
varying vec3 body_position;
void vertex(){body_position=VERTEX;}
void fragment(){
 vec3 color = tint.rgb;
 if(use_texture) color*=texture(surface_texture,UV).rgb;
 float rough=roughness_value;
 if(use_roughness) rough=texture(roughness_texture,UV).r;
 if(body_mode){
  float hands=smoothstep(0.28,0.36,abs(body_position.x))*(1.0-smoothstep(0.35,0.95,body_position.y));
  float neckline=(1.0-smoothstep(0.16,0.27,abs(body_position.x)))*smoothstep(1.02,1.30,body_position.y);
  float streak=0.55+0.40*sin(UV.x*31.0+sin(UV.y*8.0))*sin(UV.x*31.0+sin(UV.y*8.0));
  float blood=clamp(max(hands*0.95,neckline*streak),0.0,0.98);
  color=mix(color,vec3(0.17,0.006,0.011),blood);
  rough=mix(0.94,0.78,blood);
 }
 ALBEDO=color;
 ROUGHNESS=max(rough,roughness_min);
 SPECULAR=specular_value;
 CLEARCOAT=coat;
 CLEARCOAT_ROUGHNESS=0.10;
 if(use_normal){NORMAL_MAP=texture(detail_normal,UV*normal_tiling).rgb;NORMAL_MAP_DEPTH=normal_strength;}
}
