shader_type spatial;
render_mode unshaded, cull_disabled;
// A black cavity stays dark even when the capture light points into the mouth.
void fragment(){
 ALBEDO = vec3(0.0);
 ROUGHNESS = 1.0;
 SPECULAR = 0.0;
}
