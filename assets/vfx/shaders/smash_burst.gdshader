shader_type spatial;
// Stylized, high-contrast hit burst (Smash-style): a crisp star with a
// white-hot core and a saturated rim (mode 0), or a crisp bright ring
// (mode 1). Camera-facing, additive, unshaded; no soft haze. Compatibility.
render_mode blend_add, unshaded, depth_draw_never, cull_disabled, shadows_disabled;

uniform int mode = 0;
uniform vec4 core_colour : source_color = vec4(1.0, 1.0, 0.95, 1.0);
uniform vec4 rim_colour : source_color = vec4(1.0, 0.55, 0.1, 1.0);
uniform float opacity = 1.0;
// 0 at birth, 1 at the end of this burst's life.
uniform float age = 0.0;
uniform int points = 8;
uniform float inner_radius = 0.42;
uniform float sharpness = 3.0;
uniform float spin = 0.0;
uniform float ring_width = 0.07;
uniform float intensity = 1.6;

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
		vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
		vec4(0.0, 0.0, 0.0, 1.0));
}

void fragment() {
	vec2 c = UV * 2.0 - 1.0;
	float r = length(c);
	float a = atan(c.y, c.x) + spin;
	float aa = fwidth(r) * 1.5 + 0.002;
	vec3 colour;
	float alpha;
	if (mode == 0) {
		// Star: radius alternates between the inner radius and 1.0 with
		// sharp points; the centre burns white, the rim is saturated.
		float wave = pow(abs(cos(a * float(points) * 0.5)), sharpness);
		float star_r = mix(inner_radius, 1.0, wave) * 0.96;
		float inside = 1.0 - smoothstep(star_r - aa, star_r + aa, r);
		// Late in life the star hollows from the centre, so it snaps away.
		float hollow = smoothstep(0.55, 1.0, age);
		inside *= smoothstep(hollow * 0.9 - aa, hollow * 0.9 + aa, r);
		float core = 1.0 - smoothstep(0.18, 0.55, r / max(star_r, 0.001));
		colour = mix(rim_colour.rgb, core_colour.rgb, core);
		alpha = inside;
	} else {
		// Ring: one crisp bright band that thins as it expands.
		float radius = 0.86;
		float width = ring_width * (1.0 - 0.6 * age);
		float band = 1.0 - smoothstep(width - aa, width + aa, abs(r - radius));
		colour = mix(rim_colour.rgb, core_colour.rgb, 0.35);
		alpha = band;
	}
	float life = 1.0 - smoothstep(0.7, 1.0, age);
	ALBEDO = colour * intensity * alpha * life * opacity;
	ALPHA = clamp(alpha * life * opacity, 0.0, 1.0);
}
