shader_type spatial;
render_mode cull_disabled;
uniform sampler2D material_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float texture_scale = 2.0;
uniform float base_roughness = .82;
uniform float relief = .2;
void fragment(){
 vec3 col=texture(material_texture,UV*texture_scale).rgb;
 ALBEDO=col;
 float blood=smoothstep(.025,.12,col.r-col.g)*smoothstep(.04,.18,col.r);
 ROUGHNESS=mix(base_roughness,.46,blood);
 SPECULAR=.28;
}
