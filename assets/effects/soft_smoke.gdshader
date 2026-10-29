shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;
uniform sampler2D smoke_noise : repeat_enable, filter_linear;
varying float life;
void vertex() {
 life=INSTANCE_CUSTOM.y;
 MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * length(MODEL_MATRIX[0].xyz), INV_VIEW_MATRIX[1] * length(MODEL_MATRIX[1].xyz), INV_VIEW_MATRIX[2] * length(MODEL_MATRIX[2].xyz), MODEL_MATRIX[3]);
}
void fragment() {
 vec2 p=UV-vec2(.5);
 float edge=1.0-smoothstep(.16,.5,length(p));
 float curl=texture(smoke_noise,UV*1.8+vec2(TIME*.012,-TIME*.018)).r;
 float detail=texture(smoke_noise,UV*3.7-vec2(TIME*.009,TIME*.006)).r;
 ALBEDO=COLOR.rgb;
 ALPHA=edge*smoothstep(.23,.73,curl*.7+detail*.3)*COLOR.a*smoothstep(0.0,.15,life)*(1.0-smoothstep(.7,1.0,life));
}
