shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, diffuse_burley, specular_disabled;

// F40#11 / F40#6 soft cloud sea (OFF until judged; `cloud_sea.soft_sea`).
// A lit cloud floor for the deck sheets: broad billows with white sunlit tops
// and cool blue shadowed valleys, and cloud that piles up pale against any
// cliff or pillar standing in it.
//
// The noise is built on an integer hash of the lattice cell. The older deck
// material hashes with fract(sin(x) * 43758.5); on the judging GPU two
// neighbouring cells can disagree about their shared corner, which draws the
// floor as flat rectangular patches (GPU High, 8-11 Nov). An integer hash
// gives every cell the same corner value on every GPU.
uniform vec4 cloud_top : source_color = vec4(0.90, 0.93, 0.96, 1.0);
uniform vec4 cloud_mid : source_color = vec4(0.74, 0.82, 0.90, 1.0);
uniform vec4 cloud_shadow : source_color = vec4(0.42, 0.55, 0.74, 1.0);
uniform float billow_m = 130.0;
uniform vec2 sun_xz = vec2(0.6, 0.8);
uniform float alpha_min : hint_range(0.0, 1.0) = 0.55;
uniform float alpha_max : hint_range(0.0, 1.0) = 0.96;
// Cloud within this many metres in front of solid rock turns pale and opaque.
uniform float wrap_m = 45.0;
uniform float wrap_strength : hint_range(0.0, 1.0) = 0.7;
uniform sampler2D sea_depth : hint_depth_texture, repeat_disable, filter_nearest;
varying vec2 world_xz;

float cell_hash(ivec2 cell) {
	uint x = uint(cell.x) * 0x27d4eb2du;
	uint y = uint(cell.y) * 0x165667b1u;
	uint h = x ^ (y + 0x9e3779b9u + (x << 6u) + (x >> 2u));
	h ^= h >> 15u;
	h *= 0x2c1b3c6du;
	h ^= h >> 12u;
	h *= 0x297a2d39u;
	h ^= h >> 15u;
	return float(h & 0xffffu) / 65535.0;
}
float value_noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = p - cell;
	f = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
	ivec2 i = ivec2(cell);
	return mix(mix(cell_hash(i), cell_hash(i + ivec2(1, 0)), f.x),
		mix(cell_hash(i + ivec2(0, 1)), cell_hash(i + ivec2(1, 1)), f.x), f.y);
}
// Billowed height: each octave is folded so its crests are round and its
// troughs are creases, the way cumulus tops pack together.
float billows(vec2 p) {
	float total = 0.0;
	float weight = 0.5;
	float sum = 0.0;
	for (int octave = 0; octave < 5; octave++) {
		float n = value_noise(p);
		total += (1.0 - abs(n * 2.0 - 1.0)) * weight;
		sum += weight;
		p = p * 2.03 + vec2(17.3, -9.1);
		weight *= 0.52;
	}
	return total / sum;
}
void vertex() {
	world_xz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}
void fragment() {
	vec2 p = world_xz / billow_m;
	// A slow warp keeps the billows from lining up on the lattice.
	p += (vec2(value_noise(p * 0.5 + 3.1), value_noise(p * 0.5 - 7.7)) - 0.5) * 0.9;
	float height = billows(p);
	float toward_sun = billows(p + normalize(sun_xz) * 0.11);
	// Sunlit where this point stands above its neighbour toward the sun.
	float lit = clamp(0.5 + (height - toward_sun) * 3.6, 0.0, 1.0);
	// Creases between billows stay in shadow whatever the sun side.
	float crest = smoothstep(0.38, 0.72, height);
	float shade = clamp(lit * 0.75 + crest * 0.45 - 0.22, 0.0, 1.0);
	vec3 colour = mix(cloud_shadow.rgb, cloud_mid.rgb, smoothstep(0.0, 0.6, shade));
	colour = mix(colour, cloud_top.rgb, smoothstep(0.4, 1.0, shade));
	// The sheet is a support for the cloud, not a floor: fade its grazing
	// silhouette and its outer boundary, as the older deck material does.
	float facing = abs(dot(normalize(NORMAL), normalize(VIEW)));
	float grazing = smoothstep(0.025, 0.24, facing);
	vec2 edge_distance = min(UV, vec2(1.0) - UV);
	float perimeter = smoothstep(0.0, 0.055, min(edge_distance.x, edge_distance.y));
	float alpha = mix(alpha_min, alpha_max, smoothstep(0.25, 0.7, height));
	if (wrap_m > 0.0) {
		float raw_depth = texture(sea_depth, SCREEN_UV).r;
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
		vec3 ndc = vec3(SCREEN_UV, raw_depth) * 2.0 - 1.0;
#else
		vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, raw_depth);
#endif
		vec4 behind = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
		float gap = (-behind.z / behind.w) - (-VERTEX.z);
		// Broken by the billows so the pale band is not an even outline.
		float pile = (1.0 - smoothstep(0.0, wrap_m * (0.5 + height), gap)) * wrap_strength;
		colour = mix(colour, cloud_top.rgb, pile);
		alpha = mix(alpha, 1.0, pile);
	}
	ALBEDO = colour;
	ALPHA = perimeter * grazing * alpha;
	NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
	ROUGHNESS = 1.0;
}
