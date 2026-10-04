shader_type spatial;
// Stylized glowing spark streak for velocity-stretched debris (Smash-style
// sparks/embers/droplets): additive, unshaded, white-hot along the spine.
render_mode blend_add, unshaded, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec4 core_colour : source_color = vec4(1.0, 1.0, 0.9, 1.0);
uniform vec4 rim_colour : source_color = vec4(1.0, 0.6, 0.15, 1.0);
uniform float opacity = 1.0;
uniform float intensity = 1.8;

void fragment() {
	// The spark mesh is a narrow diamond; brighter toward its long axis.
	float facing = abs(dot(NORMAL, VIEW));
	vec3 colour = mix(rim_colour.rgb, core_colour.rgb, smoothstep(0.35, 0.95, facing));
	ALBEDO = colour * intensity * opacity;
	ALPHA = clamp(opacity, 0.0, 1.0);
}
