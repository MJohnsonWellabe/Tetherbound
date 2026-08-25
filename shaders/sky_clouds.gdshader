shader_type sky;

// SKY-CLOUDS. Cumulus, generated per-pixel, with no texture and no geometry.
//
// WHY, in `world_look.gd::_apply_sky`'s own words about the sky it replaces:
// a blind critic "measured the procedural sky's horizontal variation at 0.020
// against 0.140-0.289 across the Palworld references -- seven to fourteen times
// less -- and called it out plainly: no clouds, no sun disc, 'the build sky
// contributes nothing'. It named this the cheapest large win available, and it
// was right: a `ProceduralSkyMaterial` can produce a vertical gradient and a
// soft sun blob and nothing else, ever. There is no amount of tuning that puts
// a cumulus in it."
//
// Three later blind passes said the same thing with different numbers: the sky
// is "empty in all twelve frames", a "pure vertical gradient" with per-channel
// standard deviation of 2-8, occupying 30-50% of the wide frames and holding
// nothing, while every keyart panel, both meadow reference frames and four of
// five Palworld shots carry cumulus.
//
// That file's own answer was an HDRI panorama. This is the better one for the
// same slot: a panorama is an asset to source, license and ship, it cannot move,
// and it cannot change with the time of day. This is arithmetic. It costs no
// asset -- which also means `CLAUDE.md`'s no-new-assets rule for the Meadows is
// untouched -- it drifts on the wind, and every time of day drives it from the
// same `art.json` block that drives the gradient underneath it.
//
// RENDERER. `shader_type sky` runs under GL Compatibility, which `D01` locks
// this project to. No compute, no RenderingDevice, nothing on the unsupported
// list. It is fragment maths over the sky dome only -- the sky is drawn once per
// pixel of visible sky, and the cloud layers below are three octaves, not a
// raymarch, because a handheld is the target and a volumetric march is not
// affordable there.

// The gradient underneath, so this degrades to the old sky when the cloud
// amount is zero rather than to a different sky.
uniform vec3 top_colour : source_color = vec3(0.23, 0.43, 0.58);
uniform vec3 horizon_colour : source_color = vec3(0.72, 0.80, 0.76);
uniform vec3 ground_horizon_colour : source_color = vec3(0.73, 0.78, 0.81);
uniform vec3 ground_bottom_colour : source_color = vec3(0.29, 0.34, 0.28);
uniform float sky_energy = 1.0;

// Cloud shape. `coverage` is the single knob that matters: 0 is a clear sky and
// 1 is overcast, and everything interesting is between 0.35 and 0.6.
uniform float coverage : hint_range(0.0, 1.0) = 0.46;
uniform float sharpness : hint_range(0.5, 8.0) = 2.6;
uniform float scale = 1.35;
uniform float height = 0.22;
uniform vec2 wind = vec2(0.006, 0.002);

// Cloud colour. `lit` is the sunward face, `shade` the underside. Clouds are
// not white: a cumulus base is a warm grey and reading it as pure white is the
// commonest way a procedural sky looks like a screensaver.
uniform vec3 cloud_lit : source_color = vec3(1.0, 0.98, 0.94);
uniform vec3 cloud_shade : source_color = vec3(0.62, 0.66, 0.72);
uniform float sun_gain : hint_range(0.0, 3.0) = 1.1;

// The sun disc the gradient sky never had.
uniform float sun_size : hint_range(0.0, 0.2) = 0.022;
uniform float sun_glow : hint_range(0.0, 1.0) = 0.35;
uniform vec3 sun_colour : source_color = vec3(1.0, 0.96, 0.86);

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash12(i), hash12(i + vec2(1.0, 0.0)), f.x),
			mix(hash12(i + vec2(0.0, 1.0)), hash12(i + vec2(1.0, 1.0)), f.x), f.y);
}

// Three octaves, rotated between each so the lattice does not stack its
// features on the world axes -- the same banding a blind pass called "the
// loudest procedural signature" when it appeared in the ground cover.
float fbm(vec2 p) {
	const mat2 R = mat2(vec2(0.80, 0.60), vec2(-0.60, 0.80));
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 3; i++) {
		v += a * value_noise(p);
		p = R * p * 2.03;
		a *= 0.5;
	}
	return v;
}

void sky() {
	vec3 dir = normalize(EYEDIR);

	// The gradient, same shape ProceduralSkyMaterial produces so a coverage of
	// zero lands on the sky this replaces rather than on a different one.
	float up = dir.y;
	vec3 base = up >= 0.0
			? mix(horizon_colour, top_colour, pow(clamp(up, 0.0, 1.0), 0.45))
			: mix(ground_horizon_colour, ground_bottom_colour, pow(clamp(-up, 0.0, 1.0), 0.5));
	vec3 colour = base;

	// Clouds live on a plane at `height`, projected from the view direction.
	// Above the horizon only, and faded out near it -- the projection goes to
	// infinity at y=0 and would smear the noise into horizontal streaks that
	// read as a bug rather than as distance.
	if (up > 0.002) {
		vec2 plane = dir.xz / (up + height) * scale + wind * TIME;
		float horizon_fade = smoothstep(0.0, 0.16, up);

		float n = fbm(plane);
		// A second, slower sample displaces the first, which is what turns a
		// noise field into something with cauliflower edges instead of blobs.
		n = fbm(plane + vec2(n * 0.5, n * 0.35));

		float density = smoothstep(1.0 - coverage, 1.0 - coverage + (1.0 / sharpness), n);
		density *= horizon_fade;

		// Light. `d` is how far along the sun direction the cloud thins, sampled
		// by taking the field a short step sunward: where it drops, that edge is
		// facing the sun and is bright; where it holds, we are looking at the
		// shaded body. It is a cheap stand-in for a light march and it is the
		// difference between clouds with form and flat white paper.
		vec3 sun_dir = normalize(LIGHT0_DIRECTION);
		vec2 sun_step = normalize(sun_dir.xz + vec2(0.0001)) * 0.06 * scale;
		float toward_sun = fbm(plane + sun_step);
		float lit_face = clamp((n - toward_sun) * 4.0 + 0.5, 0.0, 1.0);
		vec3 cloud = mix(cloud_shade, cloud_lit, lit_face);

		// Rim: the sun burning through a thin edge.
		float rim = pow(clamp(dot(dir, sun_dir), 0.0, 1.0), 8.0);
		cloud += sun_colour * rim * sun_gain * (1.0 - density) * density * 2.0;

		colour = mix(colour, cloud, clamp(density, 0.0, 1.0));
	}

	// The sun disc, which the gradient sky never had at all.
	float sun_dot = dot(dir, normalize(LIGHT0_DIRECTION));
	float disc = smoothstep(1.0 - sun_size, 1.0 - sun_size * 0.35, sun_dot);
	float glow = pow(clamp(sun_dot, 0.0, 1.0), 24.0) * sun_glow;
	colour += sun_colour * (disc + glow) * LIGHT0_ENERGY;

	COLOR = colour * sky_energy;
}
