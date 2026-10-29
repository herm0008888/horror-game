shader_type spatial;
render_mode diffuse_burley;
uniform vec4 base_color : source_color = vec4(0.065,0.075,0.085,1.0);
uniform sampler2D aggregate : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D road_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D road_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D road_roughness : filter_linear_mipmap_anisotropic, repeat_enable;
varying vec3 world_pos;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) { vec2 i=floor(p); vec2 f=fract(p); f=f*f*(3.0-2.0*f); return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y); }
void vertex(){world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 vec2 p=world_pos.xz;
 float grain=texture(aggregate,p*0.22).r;
 float patch=noise(p*0.13);
 float wet=smoothstep(0.53,0.79,noise(p*0.065));
 ALBEDO=texture(road_albedo,p/3.0).rgb*(0.8+patch*0.2)*(1.0-wet*0.12);
 ROUGHNESS=mix(texture(road_roughness,p/3.0).r,0.38,wet*0.55);
 METALLIC=0.08;
 NORMAL_MAP=texture(road_normal,p/3.0).rgb;
 NORMAL_MAP_DEPTH=0.45;
}
