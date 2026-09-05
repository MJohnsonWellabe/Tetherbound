shader_type spatial;
render_mode unshaded,cull_disabled,blend_mix,depth_draw_never;
uniform float phase=0.0;
uniform vec4 wind_colour : source_color=vec4(0.72,0.87,0.82,1.0);
void fragment(){
	vec2 p=UV*2.0-1.0;
	float edge=pow(max(0.0,1.0-p.x*p.x),1.4)*(1.0-smoothstep(0.65,1.0,abs(p.y)));
	float drift=TIME*0.48+phase;
	float stream=sin(p.y*24.0-p.x*7.0+sin(p.x*4.0+drift)*2.7-drift*8.0);
	float filaments=pow(max(0.0,stream),18.0);
	float breaking=0.35+0.65*smoothstep(-0.25,0.75,sin(p.x*8.0+p.y*4.0+drift));
	float spiral=pow(max(0.0,sin(length(p*vec2(1.0,0.65))*29.0-atan(p.y,p.x)*2.0-drift*7.0)),24.0);
	ALBEDO=wind_colour.rgb;
	ALPHA=edge*(filaments*breaking*0.38+spiral*0.07);
}
