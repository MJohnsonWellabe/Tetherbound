shader_type spatial;
render_mode unshaded, cull_disabled;

// Opaque portal interior: three offset curtains give the existing aperture
// depth without screen/depth reads, particles or a Compatibility-only path.
uniform vec4 portal_tint : source_color = vec4(0.95, 0.81, 0.51, 1.0);
uniform float radiance = 0.25;
uniform float state_mode = 0.0; // 0 sealed, 1 locked, 2 open, 3 stirred.
uniform float flow_speed = 0.12;
uniform float depth_strength = 0.5;

void fragment() {
	vec2 aperture = (UV - vec2(0.5)) * vec2(1.0, 1.65);
	vec2 view_offset = clamp(VIEW.xy / max(abs(VIEW.z), 0.4), vec2(-1.0), vec2(1.0));
	float live = step(1.5, state_mode);
	float clock = TIME * flow_speed * live;
	float curtains = 0.0;
	for (int layer = 0; layer < 3; layer++) {
		float distance = float(layer + 1);
		vec2 p = aperture + view_offset * distance * 0.055 * depth_strength;
		float fold = sin(p.y * 5.0 + clock + distance * 1.7);
		float strand = 0.5 + 0.5 * sin(p.x * (19.0 + distance * 3.0) + fold * 2.0 - clock * distance);
		curtains += pow(strand, 8.0) / (distance * 3.0);
	}
	float edge = clamp(pow(abs(UV.x - 0.5) * 2.0, 3.0)
		+ pow(abs(UV.y - 0.5) * 2.0, 3.0), 0.0, 1.0);
	float face = mix(0.18, 0.6, edge) + curtains * depth_strength;
	ALBEDO = portal_tint.rgb * face;
	EMISSION = portal_tint.rgb * radiance * (0.2 + curtains * live);
}
