shader_type spatial;
render_mode unshaded, blend_mul, depth_draw_never;

// Static world-space weathering: stays attached to architecture, including stairs.
uniform float decay_strength : hint_range(0.0, 1.0) = 0.7;
uniform float rising_damp : hint_range(0.0, 1.0) = 0.0;
uniform vec3 stain_tint : source_color = vec3(0.26, 0.28, 0.20);
uniform bool use_rest_coordinates = false;
uniform mat4 rest_transform;
varying vec3 world_position;
varying vec3 world_normal;
float hash(vec3 p) {
 p = fract(p * 0.1031);
 p += dot(p, p.yzx + 33.33);
 return fract((p.x + p.y) * p.z);
}
float noise3(vec3 p) {
 vec3 i = floor(p); vec3 f = fract(p); f = f*f*(3.0-2.0*f);
 return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);
}
void vertex() {
 world_position = ((use_rest_coordinates ? rest_transform : MODEL_MATRIX) * vec4(VERTEX,1.0)).xyz;
 world_normal = normalize((use_rest_coordinates ? mat3(rest_transform) : MODEL_NORMAL_MATRIX) * NORMAL);
}
void fragment() {
 vec3 p = world_position;
 float broad = noise3(p * 0.85);
 float patches = noise3(p * 3.8);
 float streaks = noise3(p * vec3(11.0,0.6,11.0));
 float vertical = 1.0 - abs(normalize(world_normal).y);
 float damp = smoothstep(0.35,0.73,broad*0.72 + patches*0.28);
 float runoff = smoothstep(0.55,0.78,streaks) * smoothstep(0.35,0.65,broad) * vertical;
 float waterline = 1.0-smoothstep(-3.25,-2.45+patches*0.3,p.y);
 float wear = clamp(damp*0.85 + runoff*0.55 + waterline*vertical*rising_damp,0.0,1.0) * decay_strength;
 ALBEDO = mix(vec3(1.0),stain_tint,wear);
}
