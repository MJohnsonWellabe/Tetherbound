shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

// Analytic foam on the same transparent, shadowless plane idiom as current
// ribbons. Explicit phase (rather than TIME) lets combat pause freeze motion.
uniform float phase = 0.0;
uniform float opacity = 0.0;
uniform vec4 foam_colour : source_color = vec4(0.96, 0.99, 1.0, 1.0);
// F39#5/#14 `soft_churn_1112` (0 keeps the spoked churn): the churn inside the
// lip was broken up by angle alone, so its gaps met at the centre as a radial
// pinwheel (3/3). At 1 the churn breaks up in patches across the disc and
// fades out toward the centre.
uniform float soft_churn = 0.0;
// F39#5/#14 `v_wake` (0 keeps the full foam disc): judges 3/3 see "large,
// blurry, cloud-like foam discs strewn across open water, not a ring around
// the body". A trailing ring is turned so its local x is the swim direction;
// at 1 it keeps only the two lip arcs on either side of that direction, with
// no churn. As each ring spreads with age the arcs move apart, so the trail
// draws the two arms of a V behind the swimmer.
uniform float side_arcs = 0.0;
uniform float arc_width = 0.35;

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
	float patches = smoothstep(-0.25, 0.55, sin(p.x * 8.0 + phase * 0.31) * cos(p.y * 9.0 - phase * 0.23)
		+ 0.5 * sin((p.x + p.y) * 13.0 + phase * 0.17));
	float churn_foam = mix(churn * broken_foam, churn * patches * smoothstep(0.10, 0.34, radius), soft_churn);
	float disc = max(edge * mix(0.45, 1.0, broken_foam), churn_foam);
	float side = 1.0 - smoothstep(arc_width, arc_width + 0.2, abs(p.x) / max(radius, 0.001));
	float arcs = edge * side * mix(0.55, 1.0, broken_foam);
	ALPHA = clamp(mix(disc, arcs, side_arcs) * opacity * 1.8, 0.0, 1.0);
}
