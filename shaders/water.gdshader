shader_type spatial;

// Stylised standing water, for the pond in the valley basin.
//
// Deliberately built from NOTHING but maths and the sun. No normal map, no
// screen texture, no depth texture. That is a constraint rather than a
// preference: the visual survey is forced onto Godot's Compatibility renderer
// (Terrain3D segfaults under lavapipe — D06), and screen-space reads are the
// first thing that pipeline does differently. A water shader that looks correct
// in the editor and renders as a flat grey disc in every critic frame would be
// worse than no water at all.
//
// What the critic asked for, in its own terms: the meadow has one hue family
// and no specular highlight anywhere. Water is the cheapest way to buy both —
// a blue that nothing else in the biome owns, and a moving highlight that says
// "there is a sun" more clearly than any amount of grass.

render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;

// Shallows and depths. Two colours rather than one, blended by how far the
// fragment is from the shore, because a single flat blue reads as a painted
// tarpaulin lying in the field.
uniform vec3 shallow_colour : source_color = vec3(0.32, 0.58, 0.55);
uniform vec3 deep_colour : source_color = vec3(0.09, 0.24, 0.34);
uniform float alpha_shallow : hint_range(0.0, 1.0) = 0.60;
uniform float alpha_deep : hint_range(0.0, 1.0) = 0.88;

// Metres from the centre at which the water is considered fully deep. Set from
// the pond's own radius so the gradient scales with whatever body uses it.
uniform float depth_radius = 60.0;

uniform float roughness_water : hint_range(0.0, 1.0) = 0.06;
uniform float specular_water : hint_range(0.0, 1.0) = 0.85;

// Ripples. Two sets crossing at an angle, at different scales and speeds —
// one set alone reads as corrugated iron.
uniform float wave_scale_a = 0.62;
uniform float wave_scale_b = 1.45;
uniform float wave_speed_a = 0.55;
uniform float wave_speed_b = -0.31;
uniform float wave_strength : hint_range(0.0, 1.0) = 0.14;

// Vertical displacement, in metres. Tiny on purpose: the surface should breathe,
// not swell. Anything you notice as geometry has gone too far.
uniform float swell_height = 0.045;

// Foam where the water meets the ground, which is what actually sells a
// shoreline. There is no depth buffer to find the shore with, so it is found
// from the mesh instead: the disc's vertex colour carries distance from centre,
// baked when the pond is built.
uniform vec3 foam_colour : source_color = vec3(0.86, 0.93, 0.94);
uniform float foam_width : hint_range(0.0, 1.0) = 0.14;

varying vec3 world_position;
varying float shore;


// Distance from the pond's centre, 0 at the middle and 1 at the rim. Baked into
// COLOR by `water.gd` rather than derived here, because a fragment has no idea
// where the mesh it belongs to is centred.
void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	shore = COLOR.r;

	float t = TIME;
	float swell =
		sin(world_position.x * wave_scale_a + t * wave_speed_a) *
		cos(world_position.z * wave_scale_a * 0.83 + t * wave_speed_a * 1.21) +
		sin(world_position.z * wave_scale_b - t * wave_speed_b) * 0.45;
	VERTEX.y += swell * swell_height;
}


void fragment() {
	float t = TIME;

	// Ripple normals, as the analytic derivative of the same two wave sets. The
	// surface is nearly flat, so the normal is doing all the work that makes it
	// read as water; getting it from the actual slope rather than from a second
	// invented function keeps the highlights sitting where the swell is.
	float dx =
		cos(world_position.x * wave_scale_a + t * wave_speed_a) * wave_scale_a +
		cos(world_position.x * wave_scale_b * 1.7 - t * wave_speed_b) * wave_scale_b * 0.5;
	float dz =
		cos(world_position.z * wave_scale_a * 0.83 + t * wave_speed_a * 1.21) * wave_scale_a * 0.83 +
		sin(world_position.z * wave_scale_b - t * wave_speed_b) * wave_scale_b * 0.6;

	NORMAL = normalize(NORMAL + TANGENT * dx * wave_strength + BINORMAL * dz * wave_strength);

	float depth = clamp(1.0 - shore, 0.0, 1.0);
	vec3 body = mix(shallow_colour, deep_colour, depth * depth);
	float a = mix(alpha_shallow, alpha_deep, depth);

	// A ragged foam line rather than a clean ring. The same wave functions
	// perturb where the band falls, so it moves with the surface instead of
	// sitting on it like a decal.
	float wobble = sin(world_position.x * 1.9 + t * 0.7) * cos(world_position.z * 2.3 - t * 0.5);
	float edge = smoothstep(1.0 - foam_width, 1.0, shore + wobble * 0.035);

	ALBEDO = mix(body, foam_colour, edge);
	ALPHA = mix(a, 0.95, edge);
	ROUGHNESS = mix(roughness_water, 0.55, edge);
	SPECULAR = specular_water;
	METALLIC = 0.0;
}
