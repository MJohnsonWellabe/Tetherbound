shader_type spatial;
// F41#1 heartwood core v2 (LANE-BELOW6, 11 Nov 2026; OFF until GPU-judged).
// Judges on the landed core: "a flat gradient slab, hard edges". Each crystal
// facet takes its own value, the silhouette edge lifts (fresnel), and thin
// arcs wind slowly up inside the crystal. No noise textures.
uniform vec3 body_colour : source_color = vec3(0.21, 0.40, 0.84);
uniform vec3 glow_colour : source_color = vec3(0.31, 0.49, 1.0);
uniform float energy = 0.7;
uniform float arc_energy = 3.0;
uniform vec2 axis_xz = vec2(0.0, 0.0);
varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 facet_n = normalize(cross(dFdx(world_pos), dFdy(world_pos)));
	float facet = fract(sin(dot(floor(facet_n * 5.0 + 0.5), vec3(12.9898, 78.233, 37.719))) * 43758.5453);
	float edge = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.5);
	float angle = atan(world_pos.z - axis_xz.y, world_pos.x - axis_xz.x);
	float wind = world_pos.y * 0.55 + 2.2 * sin(angle * 2.0 + world_pos.y * 0.31) - TIME * 0.6;
	float arc = smoothstep(0.965, 1.0, abs(sin(wind)));
	float arc2 = smoothstep(0.975, 1.0, abs(sin(wind * 0.63 + angle * 3.0 + 1.7)));
	ALBEDO = body_colour * (0.5 + 0.7 * facet);
	ROUGHNESS = 0.18;
	SPECULAR = 0.6;
	EMISSION = glow_colour * energy * (0.3 + 0.9 * facet)
		+ glow_colour * energy * 1.6 * edge
		+ vec3(0.85, 0.92, 1.0) * arc_energy * max(arc, arc2);
}
