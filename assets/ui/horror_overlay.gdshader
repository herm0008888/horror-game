shader_type canvas_item;
render_mode unshaded;
uniform float vignette_strength : hint_range(0.0,0.5) = 0.22;
uniform float grain_strength : hint_range(0.0,0.05) = 0.015;
uniform float pulse_strength : hint_range(0.0,0.1) = 0.025;
uniform float tension : hint_range(0.0,1.0) = 0.25;
uniform float shock : hint_range(0.0,1.0) = 0.0;
uniform float interference : hint_range(0.0,1.0) = 0.0;
uniform float interference_y : hint_range(0.0,1.0) = 0.6;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
void fragment(){
 vec2 center=(UV-vec2(0.5))*vec2(1.0,0.86);
 float edge=smoothstep(0.31,0.68,length(center));
 float beat_phase=mod(TIME,3.4);
 float beat=exp(-pow((beat_phase-0.12)/0.09,2.0))+0.48*exp(-pow((beat_phase-0.38)/0.12,2.0));
 float border=edge*(vignette_strength+tension*0.06+beat*pulse_strength+shock*0.12);
 float noise=hash(floor(FRAGCOORD.xy*0.8)+vec2(floor(TIME*12.0)*19.0));
 float film=grain_strength*abs(noise-0.5)*2.0;
 float band=exp(-pow((UV.y-interference_y)/0.012,2.0));
 float static_alpha=band*interference*0.08*noise;
 float opacity=clamp(border+film+static_alpha,0.0,0.48);
 vec3 shade=mix(vec3(0.008,0.012,0.020),vec3(0.075,0.009,0.012),shock*0.35);
 vec3 grain_color=vec3(step(0.5,noise));
 vec3 tint=(shade*border+grain_color*film+vec3(0.32,0.37,0.40)*static_alpha)/max(opacity,0.0001);
 COLOR=vec4(tint,opacity);
}
