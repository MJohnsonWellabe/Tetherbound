shader_type spatial;
// Spark streak for velocity-stretched debris (embers, droplets): unshaded, white-hot along the spine; alpha-blended
// so the saturated edge holds against a bright sky.
render_mode blend_mix, unshaded, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec4 core_colour : source_color = vec4(1.0, 1.0, 0.9, 1.0);
uniform vec4 rim_colour : source_color = vec4(1.0, 0.6, 0.15, 1.0);
uniform float opacity = 1.0;
uniform float intensity = 1.8;

void fragment() {
	// The spark mesh is a narrow diamond; only the faces turned square to
	// the eye flare toward the hot core, so the streak stays saturated.
	float facing = abs(dot(NORMAL, VIEW));
	vec3 colour = mix(rim_colour.rgb, core_colour.rgb, smoothstep(0.8, 1.0, facing) * 0.55);
	ALBEDO = min(colour * intensity, vec3(1.0));
	ALPHA = clamp(opacity, 0.0, 1.0);
}
