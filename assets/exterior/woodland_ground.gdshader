shader_type spatial;
uniform sampler2D leaves : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D earth : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D leaf_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D earth_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void fragment(){
 vec2 p=UV*3.0;
 float n=noise(p*.28)*.65+noise(p*.81)*.35;
 float blend=smoothstep(.3,.7,n);
 vec3 a=texture(leaves,p/2.4).rgb;
 vec3 b=texture(earth,p/2.1).rgb;
 ALBEDO=mix(a,b,blend)*mix(.65,.97,noise(p*.11));
 NORMAL_MAP=mix(texture(leaf_normal,p/2.4).rgb,texture(earth_normal,p/2.1).rgb,blend);
 NORMAL_MAP_DEPTH=.65;ROUGHNESS=.94;
}
