shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back, shadows_disabled;
uniform vec4 mote_colour : source_color = vec4(0.6, 0.3, 1.0, 1.0);
uniform float opacity = 0.8;
varying float particle_alpha;
void vertex() { particle_alpha = INSTANCE_CUSTOM.r; }
void fragment() {
	float soft_edge = pow(max(dot(normalize(NORMAL), normalize(VIEW)), 0.0), 3.5);
	ALBEDO = mote_colour.rgb;
	ALPHA = soft_edge * opacity * particle_alpha;
}
