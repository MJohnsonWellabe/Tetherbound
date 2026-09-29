shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

// Analytic foam on the same transparent, shadowless plane idiom as current
// ribbons. Explicit phase (rather than TIME) lets combat pause freeze motion.
uniform float phase = 0.0;
uniform float opacity = 0.0;
uniform vec4 foam_colour : source_color = vec4(0.75, 0.91, 0.87, 1.0);

void fragment() {
	vec2 p = (UV - vec2(0.5)) * 2.0;
	float angle = atan(p.y, p.x);
	float radius = length(p);
	float ripple = 0.60 + 0.025 * sin(angle * 5.0 + phase);
	float edge = 1.0 - smoothstep(0.035, 0.10, abs(radius - ripple));
	float broken_foam = smoothstep(-0.6, 0.5, sin(angle * 7.0 + sin(angle * 3.0) + phase * 0.3));
	ALBEDO = foam_colour.rgb;
	ALPHA = edge * mix(0.3, 1.0, broken_foam) * opacity;
}
