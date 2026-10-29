shader_type spatial;
render_mode unshaded,blend_mix,depth_draw_never,cull_disabled,shadows_disabled;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void fragment(){
 float cloud=noise(UV*vec2(7.,3.)+vec2(TIME*.016,0.));
 float fade=smoothstep(0.,.2,UV.x)*smoothstep(0.,.2,1.-UV.x)*smoothstep(0.,.3,UV.y)*smoothstep(0.,.25,1.-UV.y);
 ALBEDO=vec3(.19,.24,.25);ALPHA=fade*cloud*.045*exp(-dot((UV-vec2(.5))*vec2(2.,3.),(UV-vec2(.5))*vec2(2.,3.)));
}
