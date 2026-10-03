shader_type spatial;
// Flat ground-plane impact mark drawn on a PlaneMesh just above the contact
// ground. Procedural (no texture), depth-tested, Compatibility-safe.
// mode 0 scorch: charred patch with a cooling ember rim (fire aftermath).
// mode 1 dust: pale scuffed ring of kicked earth (stone contact/aftermath).
// mode 2 shockwave: thin expanding annulus (contact moment).
// mode 3 burn: dark strike burn with radial branching cracks (lightning).
render_mode blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform int mode = 0;
uniform vec4 mark_colour : source_color = vec4(0.12, 0.09, 0.07, 1.0);
uniform vec4 glow_colour : source_color = vec4(1.0, 0.45, 0.12, 1.0);
uniform float opacity = 0.8;
// 0 at birth, 1 at end of this mark's life; drives ring radius and cooling.
uniform float age = 0.0;
uniform float glow_strength = 1.4;
uniform float breakup = 0.35;
uniform float ring_width = 0.12;
uniform float seed = 0.0;
uniform int crack_count = 7;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7)) + seed * 17.13) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float total = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 4; i++) {
		total += noise(p) * amplitude;
		p *= 2.03;
		amplitude *= 0.5;
	}
	return total;
}

void fragment() {
	vec2 centered = UV * 2.0 - 1.0;
	float r = length(centered);
	float angle = atan(centered.y, centered.x);
	float n = fbm(centered * 3.1 + vec2(seed * 3.7, seed * 1.3));
	// Irregular silhouette: the radius threshold wobbles with low-frequency noise.
	float edge = 1.0 - breakup * (n - 0.35);
	float alpha = 0.0;
	vec3 albedo = mark_colour.rgb;
	vec3 emission = vec3(0.0);
	if (mode == 0) {
		float body = 1.0 - smoothstep(edge * 0.55, edge * 0.92, r);
		float soot = fbm(centered * 7.0 + seed);
		alpha = body * (0.55 + 0.45 * soot);
		albedo = mix(mark_colour.rgb * 0.6, mark_colour.rgb * 1.5, soot);
		float rim = smoothstep(edge * 0.40, edge * 0.70, r) * (1.0 - smoothstep(edge * 0.70, edge * 0.92, r));
		float embers = smoothstep(0.55, 0.85, fbm(centered * 11.0 + vec2(seed)));
		float heat = pow(1.0 - age, 2.2);
		emission = glow_colour.rgb * glow_strength * heat * (rim * 0.8 + embers * body * 0.9);
	} else if (mode == 1) {
		float inner = smoothstep(edge * 0.18, edge * 0.55, r);
		float outer = 1.0 - smoothstep(edge * 0.62, edge * 0.98, r);
		float grains = fbm(centered * 14.0 + vec2(seed * 2.0));
		alpha = inner * outer * (0.45 + 0.55 * grains);
		albedo = mix(mark_colour.rgb * 0.8, mark_colour.rgb * 1.2, grains);
	} else if (mode == 2) {
		float radius = mix(0.12, 0.92, sqrt(age));
		float width = ring_width * (1.0 - 0.5 * age);
		float band = 1.0 - smoothstep(0.0, width, abs(r - radius * edge));
		alpha = band * (1.0 - age);
		albedo = mark_colour.rgb;
		emission = glow_colour.rgb * glow_strength * band * pow(1.0 - age, 1.5);
	} else {
		float core = 1.0 - smoothstep(edge * 0.10, edge * 0.42, r);
		float sector = angle / 6.2831853 * float(crack_count) + n * 1.6;
		// Thin line along each sector's centre, wider near the strike point.
		float crack_line = 1.0 - smoothstep(0.015, 0.045 + 0.05 * (1.0 - r), abs(fract(sector) - 0.5));
		float wiggle = fbm(vec2(r * 9.0, floor(sector) + seed));
		float reach = smoothstep(edge * (0.55 + 0.35 * wiggle), edge * (0.35 + 0.2 * wiggle), r);
		float cracks = crack_line * reach * step(0.08, r);
		alpha = clamp(core * 0.85 + cracks * 0.9, 0.0, 1.0);
		albedo = mark_colour.rgb;
		float heat = pow(1.0 - age, 3.0);
		emission = glow_colour.rgb * glow_strength * heat * (cracks + core * 0.5);
	}
	ALBEDO = albedo;
	EMISSION = emission;
	ROUGHNESS = 1.0;
	SPECULAR = 0.1;
	ALPHA = clamp(alpha * opacity, 0.0, 1.0);
}
