shader_type spatial;

// Cloudreach uses the same generated tuft / flower / bush meshes as the
// Meadows, but its stacked cliff plates cannot sample one Terrain3D height at
// each XZ coordinate. Instances are therefore authored onto each plate/ribbon
// by cloudreach_ground_cover.gd and this lightweight shader supplies the same
// base-to-tip colour, softened normals and travelling wind response.
render_mode cull_disabled, depth_prepass_alpha, diffuse_lambert, specular_disabled;

uniform vec3 tint_base : source_color = vec3(0.18, 0.25, 0.08);
uniform vec3 tint_tip : source_color = vec3(0.48, 0.56, 0.18);
uniform float shade_jitter : hint_range(0.0, 1.0) = 0.18;
uniform float normal_soften : hint_range(0.0, 1.0) = 0.55;
uniform float wind_strength : hint_range(0.0, 0.5) = 0.10;
uniform float wind_scale = 0.075;
uniform float gust_strength : hint_range(0.0, 1.0) = 0.32;
uniform float gust_speed = 5.5;
uniform float gust_length = 34.0;
uniform vec2 wind_dir = vec2(0.86, 0.51);
uniform float leaf_cut : hint_range(0.0, 1.0) = 0.0;
uniform float leaf_root_darken : hint_range(0.0, 1.0) = 0.42;
uniform vec3 tint_wood : source_color = vec3(0.28, 0.22, 0.13);

varying float v_t;
varying float v_shade;
varying vec2 v_leaf_uv;
varying float v_wood;

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void vertex() {
	vec3 origin = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec2 direction = normalize(wind_dir);
	float front = dot(origin.xz, direction) / max(gust_length, 0.01) - TIME * gust_speed / max(gust_length, 0.01);
	float ambient = sin(TIME * 1.7 + dot(origin.xz, vec2(0.041, 0.057)));
	float gust = max(0.0, sin(front * 6.2831853)) * gust_strength;
	float bend = (ambient * 0.45 + gust) * wind_strength * UV.y;
	VERTEX.xz += direction * bend;
	NORMAL = normalize(mix(NORMAL, vec3(0.0, 1.0, 0.0), normal_soften));
	v_t = UV.y;
	v_shade = mix(1.0 - shade_jitter, 1.0 + shade_jitter, hash12(origin.xz));
	v_leaf_uv = vec2(UV.x, UV2.x);
	v_wood = step(1.5, UV2.y);
}

void fragment() {
	vec3 colour = mix(tint_base, tint_tip, smoothstep(0.0, 1.0, v_t));
	float leaf_root_light = mix(1.0 - leaf_root_darken, 1.0,
		smoothstep(0.0, 1.0, v_leaf_uv.y));
	float root_light = mix(1.0, leaf_root_light, leaf_cut * (1.0 - v_wood));
	ALBEDO = mix(colour * root_light, tint_wood, v_wood) * v_shade;
	ROUGHNESS = 0.92;
	float rounded_leaf = sin(clamp(v_leaf_uv.y, 0.0, 1.0) * 3.14159265);
	float leaf_mask = 1.0 - smoothstep(rounded_leaf * 0.52, rounded_leaf * 0.52 + 0.08,
		abs(v_leaf_uv.x - 0.5));
	ALPHA = mix(1.0, leaf_mask, leaf_cut * (1.0 - v_wood));
	ALPHA_SCISSOR_THRESHOLD = 0.45;
}
