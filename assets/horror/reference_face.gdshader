shader_type spatial;
uniform sampler2D surface_texture : source_color, filter_linear_mipmap, repeat_disable;
uniform vec4 tint : source_color = vec4(1.0);
uniform float surface_roughness = 0.95;
uniform float surface_specular = 0.08;
uniform float scream = 0.0;
void fragment(){
 vec3 photo = texture(surface_texture, UV).rgb;
 float value = dot(photo,vec3(0.2126,0.7152,0.0722));
 vec3 corpse = mix(photo,vec3(value),0.18)*vec3(0.91,0.92,0.88);
 ALBEDO = corpse*tint.rgb;
 ROUGHNESS = surface_roughness;
 SPECULAR = surface_specular;
}
