shader_type spatial;
uniform sampler2D surface_texture : source_color, filter_nearest, repeat_enable;
uniform sampler2D underside_texture : source_color, filter_nearest, repeat_enable;
uniform vec4 atlas_rect = vec4(0.0,0.0,1.0,1.0);
uniform vec4 underside_rect = vec4(0.0,0.0,1.0,1.0);
uniform bool use_atlas = false;
uniform float wall_height = 0.0;
uniform vec2 tile_size = vec2(1.0);
uniform vec4 tint : source_color = vec4(1.0);
uniform bool horizontal_grain_x = false;
uniform bool plaster_underside = false;
uniform bool world_space = false;
varying vec3 surface_position;
varying vec3 surface_normal;
void vertex(){
 surface_position = world_space ? (MODEL_MATRIX*vec4(VERTEX,1.0)).xyz : VERTEX;
 surface_normal = world_space ? normalize(mat3(MODEL_MATRIX)*NORMAL) : NORMAL;
}
void fragment(){
 vec3 n=abs(normalize(surface_normal));
 vec2 coords;
 if(n.y>n.x && n.y>n.z){
  coords=horizontal_grain_x ? surface_position.zx : surface_position.xz;
 }else if(n.x>n.z){
  coords=surface_position.zy;
 }else{
  coords=surface_position.xy;
 }
 vec2 uv=coords/tile_size;
 if(use_atlas){
  // Sample only the intended material patch. Pixel centers prevent atlas bleed.
  vec2 patch_uv=vec2(uv.x,-uv.y);
  // Mirror patch borders rather than cutting from one edge to the other.
  patch_uv=1.0-abs(fract(patch_uv*0.5)*2.0-1.0);
  if(wall_height>0.0 && n.y<0.5){
   // Each storey uses a whole upright wall patch, with no mid-wall wrap.
   float storey_y=mod(surface_position.y+0.0001,wall_height);
   patch_uv.y=1.0-clamp(storey_y/wall_height,0.0,1.0);
  }
  vec2 pixel_uv=(clamp(floor(patch_uv*128.0),vec2(0.0),vec2(127.0))+0.5)/128.0;
  uv=atlas_rect.xy+pixel_uv*atlas_rect.zw;
 }
 vec3 color=texture(surface_texture,uv).rgb*tint.rgb;
 if(plaster_underside && surface_normal.y < -0.5){
  vec2 ceiling_uv=surface_position.xz/2.5;
  if(use_atlas) ceiling_uv=underside_rect.xy+((floor(fract(ceiling_uv)*128.0)+0.5)/128.0)*underside_rect.zw;
  color=texture(underside_texture,ceiling_uv).rgb;
 }
 ALBEDO=floor(clamp(color,0.0,1.0)*31.0)/31.0;
 ROUGHNESS=0.95;
}
