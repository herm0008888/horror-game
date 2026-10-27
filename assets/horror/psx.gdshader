shader_type spatial;
uniform sampler2D surface_texture : source_color, filter_nearest_mipmap, repeat_enable;
uniform vec4 tint : source_color = vec4(1.0);
uniform vec2 tiling = vec2(1.0);
uniform float emission_strength = 0.0;
void fragment(){
 // Normal perspective-correct UVs keep textures attached to their surfaces.
 vec3 col=texture(surface_texture,UV*tiling).rgb*tint.rgb;
 ALBEDO=floor(clamp(col,0.0,1.0)*31.0)/31.0;
 EMISSION=ALBEDO*emission_strength;
 ROUGHNESS=1.0;
}
