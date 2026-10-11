shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

// Analytic foam on the same transparent, shadowless plane idiom as current
// ribbons. Explicit phase (rather than TIME) lets combat pause freeze motion.
uniform float phase = 0.0;
uniform float opacity = 0.0;
uniform vec4 foam_colour : source_color = vec4(0.96, 0.99, 1.0, 1.0);

void fragment() {
	vec2 p = (UV - vec2(0.5)) * 2.0;
	float angle = atan(p.y, p.x);
	float radius = length(p);
	float ripple = 0.60 + 0.025 * sin(angle * 5.0 + phase);
	// A broad white lip where the body breaks the surface, plus a soft churn
	// inside it: a thin pale ring disappeared against the cyan shallows.
	float edge = 1.0 - smoothstep(0.07, 0.20, abs(radius - ripple));
	float churn = (1.0 - smoothstep(0.15, ripple, radius)) * 0.45;
	float broken_foam = smoothstep(-0.6, 0.5, sin(angle * 7.0 + sin(angle * 3.0) + phase * 0.3));
	ALBEDO = foam_colour.rgb;
	ALPHA = clamp(max(edge * mix(0.45, 1.0, broken_foam), churn * broken_foam) * opacity * 1.8, 0.0, 1.0);
}
