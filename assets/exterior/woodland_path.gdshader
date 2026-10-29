shader_type spatial;
uniform sampler2D ground_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_map : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
void fragment(){
 ALBEDO=texture(ground_map,UV).rgb*vec3(.75,.72,.65);
 NORMAL_MAP=texture(normal_map,UV).rgb;NORMAL_MAP_DEPTH=.8;ROUGHNESS=.93;
}
