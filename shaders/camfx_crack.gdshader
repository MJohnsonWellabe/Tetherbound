shader_type spatial;
// camfx.json `impact_fx` (cameras-and-effects lane, 1 Nov): the ground crack a
// heavy blow leaves at the struck creature's feet. Jagged radial fissures and a
// small crushed centre, drawn on a flat quad; `glow` lights the fissures in the
// element's colour (electric scorch, fire embers) and fades first.
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec4 crack_colour : source_color = vec4(0.13, 0.10, 0.07, 1.0);
uniform vec4 glow_colour : source_color = vec4(1.0, 0.85, 0.4, 1.0);
uniform float glow = 0.0;
uniform float fade = 1.0;
uniform float seed = 0.0;
uniform float rays = 7.0;

float hash11(float p) {
	return fract(sin(p * 91.345 + seed * 13.7) * 47453.5453);
}

float vnoise1(float x) {
	float i = floor(x);
	float f = fract(x);
	return mix(hash11(i), hash11(i + 1.0), f * f * (3.0 - 2.0 * f));
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float ang = atan(p.y, p.x) / 6.2831853 + 0.5;
	float line = 0.0;
	for (int k = 0; k < 9; k++) {
		if (float(k) >= rays) {
			break;
		}
		float base = (float(k) + hash11(float(k)) * 0.6) / rays;
		float reach = 0.55 + 0.45 * hash11(float(k) + 7.0);
		// The fissure wanders as it runs out.
		float wobble = (vnoise1(r * 9.0 + float(k) * 3.1) - 0.5) * 0.06;
		float d = abs(fract(ang - base - wobble + 0.5) - 0.5) * 6.2831853 * r;
		float width = 0.035 * (1.0 - r / reach) + 0.004;
		float seg = (1.0 - smoothstep(width * 0.5, width, d)) * step(r, reach);
		line = max(line, seg);
	}
	float crater = 1.0 - smoothstep(0.08, 0.2, r + (vnoise1(ang * 40.0) - 0.5) * 0.05);
	float mask = max(line, crater * 0.85);
	mask *= 1.0 - smoothstep(0.75, 1.0, r);
	vec3 colour = mix(crack_colour.rgb, glow_colour.rgb * 1.6, clamp(glow * line, 0.0, 1.0));
	ALBEDO = colour;
	ALPHA = clamp(mask * fade, 0.0, 1.0) * 0.85;
}
