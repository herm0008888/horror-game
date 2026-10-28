shader_type spatial;
render_mode cull_disabled;
void fragment(){
 float strand=.5+.5*sin(UV.x*83.0+sin(UV.y*13.0)*.7);
 float breakup=.5+.5*sin(UV.y*27.0+UV.x*11.0);
 ALBEDO=mix(vec3(.012,.009,.007),vec3(.045,.032,.021),strand*.6+breakup*.15);
 ROUGHNESS=.78+breakup*.12;
 SPECULAR=.0;
 ANISOTROPY=.0;
}


