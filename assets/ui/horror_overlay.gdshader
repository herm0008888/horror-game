shader_type canvas_item;
render_mode unshaded;
uniform sampler2D scene_color : hint_screen_texture, repeat_disable, filter_linear;
uniform float vignette_strength : hint_range(0.0,0.5) = 0.30;
uniform float grain_strength : hint_range(0.0,0.05) = 0.018;
uniform float pulse_strength : hint_range(0.0,0.1) = 0.032;
uniform float tension : hint_range(0.0,1.0) = 0.25;
uniform float shock : hint_range(0.0,1.0) = 0.0;
uniform float interference : hint_range(0.0,1.0) = 0.0;
uniform float interference_y : hint_range(0.0,1.0) = 0.6;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
void fragment(){
 vec2 center=(UV-vec2(0.5))*vec2(1.0,0.86);
 float edge=smoothstep(0.27,0.68,length(center));
 float beat_phase=mod(TIME,3.4);
 float beat=exp(-pow((beat_phase-0.12)/0.09,2.0))+0.48*exp(-pow((beat_phase-0.38)/0.12,2.0));
 float border=edge*(vignette_strength+tension*0.08+beat*pulse_strength*(0.35+tension)+shock*0.12);
 // Fixed edge grime, without blur or moving UVs.
 float dirt=smoothstep(0.56,0.94,hash(floor(UV*vec2(39.0,25.0))))*edge*edge*0.055;
 float noise=hash(floor(FRAGCOORD.xy*0.8)+vec2(floor(TIME*12.0)*19.0));
 float film=grain_strength*abs(noise-0.5)*2.0;
 float band=exp(-pow((UV.y-interference_y)/0.012,2.0));
 float static_alpha=band*interference*0.08*noise;
 float opacity=clamp(border+dirt+film+static_alpha,0.0,0.52);
 vec3 shade=mix(vec3(0.009,0.014,0.013),vec3(0.065,0.012,0.008),shock*0.35);
 vec3 grain_color=vec3(step(0.5,noise));
 vec3 tint=(shade*border+vec3(0.025,0.021,0.013)*dirt+grain_color*film+vec3(0.32,0.37,0.40)*static_alpha)/max(opacity,0.0001);
 // A restrained lens response grows only during pursuit; center stays readable.
 vec2 radial=SCREEN_UV-vec2(.5);
 float fear=smoothstep(.4,1.0,tension);
 vec2 split=radial*(.0012*fear+.0015*shock)*edge;
 vec3 scene=texture(scene_color,SCREEN_UV).rgb;
 scene.r=texture(scene_color,SCREEN_UV+split).r;
 scene.b=texture(scene_color,SCREEN_UV-split).b;
 float luma=dot(scene,vec3(.2126,.7152,.0722));
 scene=mix(scene,vec3(luma),fear*.17);
 float breath=sin(TIME*1.4)*.5+.5;
 scene*=1.0-edge*fear*breath*.035;
 COLOR=vec4(mix(scene,tint,opacity),1.0);
}
