shader_type spatial;
render_mode cull_disabled;
uniform sampler2D material_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float texture_scale = 2.0;
uniform float base_roughness = .82;
uniform float relief = .2;
varying vec3 rest_position;
varying vec3 rest_normal;
void vertex(){rest_position=VERTEX;rest_normal=NORMAL;}
void fragment(){
 vec3 w=pow(abs(rest_normal),vec3(4.0));w/=max(dot(w,vec3(1.0)),.0001);
 vec3 p=rest_position*texture_scale;
 vec3 col=texture(material_texture,p.yz).rgb*w.x+texture(material_texture,p.xz).rgb*w.y+texture(material_texture,p.xy).rgb*w.z;
 ALBEDO=col;
 float blood=smoothstep(.025,.12,col.r-col.g)*smoothstep(.04,.18,col.r);
 ROUGHNESS=mix(base_roughness,.46,blood);
 SPECULAR=.28;
}
