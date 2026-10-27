shader_type spatial;
uniform float scream = 0.0;
varying vec3 skin_position;
void vertex(){skin_position=VERTEX;}
void fragment(){
 vec3 skin=vec3(0.29,0.28,0.255);
 float hands=smoothstep(0.31,0.38,abs(skin_position.x))*(1.0-smoothstep(0.32,0.72,skin_position.y));
 float smear=0.72+0.18*sin(skin_position.x*43.0+skin_position.z*17.0);
 ALBEDO=mix(skin,vec3(0.13,0.018,0.016),hands*smear);
 ROUGHNESS=1.0;
 SPECULAR=0.08;
}
