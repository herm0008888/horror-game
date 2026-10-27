shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float clock=0.0;
uniform float panic=0.0;
void fragment(){
 vec2 uv=SCREEN_UV;
 vec3 color=texture(screen_texture,uv).rgb;
 float vignette=1.0-smoothstep(0.22,0.78,length((SCREEN_UV-.5)*vec2(1.15,1.0)));
 color*=mix(0.83,1.0,vignette);
 color*=1.0-mod(FRAGCOORD.y,2.0)*.008;
 color=mix(color,vec3(color.r*.9,0.0,0.0),panic*.15);
 COLOR=vec4(color,1.0);
}
