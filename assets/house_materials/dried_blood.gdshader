shader_type spatial;
render_mode cull_disabled;
uniform vec2 extent=vec2(1.0);
varying vec2 stain_uv;
float grain(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
void vertex(){stain_uv=VERTEX.xz/extent;}
void fragment(){
	float coarse=grain(floor(stain_uv*17.0));
	float radius=length(stain_uv);
	if(radius>.66+coarse*.14) discard;
	float fine=grain(floor(stain_uv*350.0));
	if(fine<.035+radius*.13) discard;
	ALBEDO=mix(vec3(.045,.012,.008),vec3(.13,.021,.014),fine*.65+coarse*.25);
	ROUGHNESS=.91;
}
