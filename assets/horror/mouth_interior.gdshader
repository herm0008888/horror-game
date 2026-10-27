shader_type spatial;
render_mode cull_disabled;
uniform vec4 tint : source_color = vec4(0.047,0.006,0.012,1.0);
void fragment(){
 ALBEDO = tint.rgb;
 ROUGHNESS = 1.0;
 SPECULAR = 0.05;
}
