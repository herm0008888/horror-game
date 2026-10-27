shader_type spatial;
uniform vec3 base_color : source_color = vec3(0.31,0.34,0.35);
varying vec3 world_position;
varying vec3 world_normal;
void vertex(){world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;world_normal=normalize(mat3(MODEL_MATRIX)*NORMAL);}
void fragment(){
 vec3 n=abs(world_normal);vec2 uv=world_position.xz;
 if(n.x>n.y && n.x>n.z) uv=world_position.zy;
 else if(n.z>n.y) uv=world_position.xy;
 vec2 cell=fract(uv);float line=step(0.025,min(min(cell.x,1.0-cell.x),min(cell.y,1.0-cell.y)));
 float checker=mod(floor(uv.x)+floor(uv.y),2.0);
 ALBEDO=mix(vec3(0.085),base_color*(0.88+checker*0.12),line);
 ROUGHNESS=1.0;
}
