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
// VP1 (visual parity program, 2026-09-01). The first version of this shader
// put clouds in the sky and every blind pass since has named the same defect
// about them: "smeared airbrush blotches in every outdoor frame", "gaussian-
// blurred streaks rather than clouds with any internal form". Three reasons,
// each fixed below and each a separate knob so a time of day can tune it:
//
//   1. THREE OCTAVES OF PLAIN VALUE NOISE IS A BLOB. Value noise is smooth by
//      construction; summing three octaves of it gives a soft undulating field
//      and nothing with an edge. Cumulus have cauliflower tops because their
//      high-frequency detail is BILLOWED (1 - |2n - 1|): the fold puts a crease
//      at every zero crossing, which is what reads as a lobed silhouette. The
//      field is now two plain octaves for the mass and three billowed octaves
//      for the lobes (`fbm_cumulus`).
//   2. A 1/SHARPNESS-WIDE SMOOTHSTEP IS A FEATHERED EDGE. The density ramp was
//      `smoothstep(t0, t0 + 1/sharpness, n)`, a gradient nearly as wide as the
//      cloud. A real cloud edge is close to binary at the horizon-sized scale
//      the eye sees it at: `edge_softness` is now the whole ramp width, and a
//      power curve inside it keeps the body opaque instead of translucent.
//   3. A FLAT PLANE HAS NO PERSPECTIVE. `dir.xz / (up + height)` is a plane at
//      fixed height, which makes every cloud the same apparent size from zenith
//      to horizon and smears the noise into streaks as `up` goes to zero. A
//      shell projection (`cloud_altitude / up`) makes clouds LARGE overhead and
//      compressed toward the horizon, which is the single strongest depth cue
//      a sky has, and the high octaves fade out where the compression would
//      alias them into noise.
//
// Plus a cloud BASE (dark warm-grey underside, distinct from the shaded side),
// a thin high cirrus layer so the sky has two depths instead of one, and a
// horizon haze band that lands on `horizon_colour` -- the same colour the
// terrain fog uses (art.json's own B12 note) -- so sky and land meet in one
// band instead of at a hard line, which a blind pass named at 03-rise-overlook.
//
// RENDERER. `shader_type sky` runs under GL Compatibility, which `D01` locks
// this project to. No compute, no RenderingDevice, nothing on the unsupported
// list. It is fragment maths over the sky dome only -- the sky is drawn once per
// pixel of visible sky, and the cloud field below is five octaves plus a light
// sample and two cirrus octaves, not a raymarch, because a handheld is the
// target and a volumetric march is not affordable there. ~17 value-noise
// evaluations per sky pixel against the previous 9.
//
// Every uniform below that a time of day may want is driven from `art.json`'s
// `sky` block through `world_look.gd::_apply_cloud_sky`; a preset that does not
// set one keeps the default here, which is tuned for the day sky.

// The gradient underneath, so this degrades to the old sky when the cloud
// amount is zero rather than to a different sky.
uniform vec3 top_colour : source_color = vec3(0.23, 0.43, 0.58);
uniform vec3 horizon_colour : source_color = vec3(0.72, 0.80, 0.76);
uniform vec3 ground_horizon_colour : source_color = vec3(0.73, 0.78, 0.81);
uniform vec3 ground_bottom_colour : source_color = vec3(0.29, 0.34, 0.28);
uniform float sky_energy = 1.0;

// Cloud shape. `coverage` is the single knob that matters: 0 is a clear sky and
// 1 is overcast, and everything interesting is between 0.35 and 0.6.
// `edge_softness` is the width of the density ramp in noise units: 0.02 is a
// cut-out, 0.15 is soft. `sharpness` is kept so an old preset still parses; it
// is only read when `edge_softness` is left at zero.
uniform float coverage : hint_range(0.0, 1.0) = 0.5;
uniform float sharpness : hint_range(0.5, 8.0) = 2.6;
uniform float edge_softness : hint_range(0.0, 0.3) = 0.06;
uniform float scale = 1.5;
// Shell projection: larger is a taller cloud deck, i.e. larger clouds
// overhead and more compression toward the horizon.
uniform float cloud_altitude : hint_range(0.2, 3.0) = 0.9;
// Kept for old presets; unused by the shell projection.
uniform float height = 0.22;
uniform vec2 wind = vec2(0.006, 0.002);

// TIME WRAP. `TIME` grows without bound for the lifetime of the render, and the
// two wind-drift terms below (`wind * TIME`, `wind * 1.8 * TIME`) feed that
// ever-growing value straight into fract()/floor() inside `value_noise()` (via
// `hash12`'s `fract(p * 0.1031)`). Measured over five rounds on one boot, one
// stand: Environment/sky uniforms are bit-identical at shutter between a clean
// early frame (TIME 172.6s, R-G -5.94) and a frame gone uniform red/maroon later
// (`day`, R-G +84.5) -- with a brightening trend already visible by TIME 1376.8s
// (mean +50%, hue still clean at R-G -8.47). Ten other explanations were
// falsified, including per-camera/delivery routing (one Environment object, no
// overrides). Because `world_look.gd::_apply_sky` sets
// `ambient_light_source = AMBIENT_SOURCE_SKY`, a sky that degenerates this way
// drags terrain and near rocks red too, even though nothing else in the scene
// changed -- which is why a sky-only precision bug reads as a whole-frame wash.
// Wrapping TIME keeps that fract()/floor() argument bounded for the run's whole
// lifetime instead of growing forever. DO NOT replace `t_wrapped` below with raw
// `TIME` again without re-reading this comment.
//
// Wrap-period arithmetic. The two drift terms share one `wind` vector but
// different multipliers: `wind * TIME` (cumulus, `plane`) and `wind * 1.8 * TIME`
// (cirrus, `plane2`). For a `mod(TIME, time_wrap)` reset not to also shear the
// noise lattice it samples, the drift accumulated over one period must land back
// on an integer number of grid cells in BOTH axes, for BOTH layers, at the SAME
// period (they share one TIME). With the default wind = (0.006, 0.002) -- an
// exact 3:1 ratio -- let A = wind.x * time_wrap; wind.y * time_wrap is then
// always A/3, so the real constraint is making A an integer (cumulus) AND
// 1.8*A an integer (cirrus) at once. 1.8 = 9/5 in lowest terms, so 1.8*A is only
// an integer when A is a multiple of 5, and A/3 is only an integer when A is a
// multiple of 3 -- so the smallest A satisfying both is lcm(3, 5) = 15, giving
// time_wrap = 15 / 0.006 = 2500 seconds (~41.7 min). At that period:
//   cumulus drift  wind * time_wrap       = (15, 5)  -- exact integers
//   cirrus  drift  wind * 1.8 * time_wrap = (27, 9)  -- exact integers
// so both layers land back on a grid boundary simultaneously: no fractional-
// interpolation shear at the seam. This is NOT the noise FIELD repeating, only
// its lattice alignment: `hash12`'s own internal cycle (1/0.1031 ~= 9.699321,
// not an integer) means an integer lattice shift lands on a different,
// uncorrelated pseudo-random cell, so the cloud/cirrus SHAPES still visibly
// re-arrange in that one frame -- true bit-for-bit seamlessness is not
// achievable with this hash, only shear-free alignment is. The accepted
// residual: a rare (once per ~42 minutes of elapsed render time), clean
// grid-aligned pop instead of a constant tear -- versus the permanent red wash
// this replaces. Exposed as a uniform, not a constant, because this exact
// arithmetic is keyed to the DEFAULT `wind` above: a time-of-day preset that
// sets a different `wind` (a different ratio, not 3:1) needs its own recomputed
// `time_wrap` to keep the alignment, and hardcoding this value would silently
// break that preset's seam instead of just needing a new number.
uniform float time_wrap : hint_range(60.0, 6000.0) = 2500.0;

// Cloud colour. `lit` is the sunward face, `shade` the side away from the sun,
// `base` the flat underside of a thick cloud. Clouds are not white: a cumulus
// base is a warm grey and reading it as pure white is the commonest way a
// procedural sky looks like a screensaver.
uniform vec3 cloud_lit : source_color = vec3(1.0, 0.97, 0.93);
uniform vec3 cloud_shade : source_color = vec3(0.62, 0.69, 0.77);
uniform vec3 cloud_base : source_color = vec3(0.55, 0.60, 0.67);
// How hard the lit/shade split is. 4.0 was the old hard-coded value and read
// as flat white paper; 6-8 gives each lobe a lit top and a shaded flank.
uniform float lit_contrast : hint_range(1.0, 12.0) = 6.0;
uniform float sun_gain : hint_range(0.0, 3.0) = 1.1;

// A second, thin, high layer -- cirrus streaks -- so the sky has two depths.
// `high_opacity` 0 removes it.
uniform float high_coverage : hint_range(0.0, 1.0) = 0.3;
uniform float high_scale = 0.55;
uniform float high_opacity : hint_range(0.0, 1.0) = 0.35;

// Horizon haze: how far up the dome (in `up`, 0..1) the haze colour reaches
// and how strongly it takes over at the line itself.
uniform float haze_height : hint_range(0.0, 0.5) = 0.14;
uniform float haze_strength : hint_range(0.0, 1.0) = 0.55;
// VP1 sky retune round 1. The haze used to mix straight to `horizon_colour`,
// which is right for the SEAM with the terrain fog but wrong for the haze
// band itself: real atmospheric haze reads slightly cooler/bluer than the lit
// horizon under it (more air, more scattered blue), and reusing the warm
// horizon tint for both flattened the whole lower dome to one near-white
// wash. Defaults to `horizon_colour`'s own default so an old preset that never
// sets this keeps exactly the prior look.
uniform vec3 haze_colour : source_color = vec3(0.72, 0.80, 0.76);

// The sun disc the gradient sky never had.
uniform float sun_size : hint_range(0.0, 0.2) = 0.022;
uniform float sun_glow : hint_range(0.0, 1.0) = 0.35;
// How much of the disc's radius is falloff. 1.0 is a razor edge, 0.0 a full
// gradient from centre to rim. See the `disc` line in sky() for why this became
// a uniform (JUDGE-6: "a soft blurry ellipse with no disc edge").
uniform float disc_edge : hint_range(0.0, 0.99) = 0.35;
// The `glow` term's falloff exponent. This used to be a hardcoded `24.0`,
// which fixes the halo's angular width regardless of `sun_size`/`disc_edge`
// (those only shape `disc`, the crisp body) or `sun_glow` (which only scales
// the halo's brightness, not its extent). At exponent E, glow falls to half
// its peak at cos(theta) = 2^(-1/E), so the halo's full diameter in degrees is
// `2 * acos(2^(-1/E)) * 180/PI`. E=24.0 (the old constant) works out to about
// 27.4 degrees across -- roughly 54x the real sun's ~0.5-degree width -- which
// is what read as a giant white blob instead of a disc with a glow around it.
// Higher E narrows the halo; e.g. E=200.0 is about 9.5 degrees, E=120.0 about
// 12.3 degrees. Default kept at the old 24.0 so any preset that does not set
// this renders exactly as before.
uniform float sun_glow_falloff : hint_range(4.0, 600.0) = 24.0;
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

const mat2 ROT = mat2(vec2(0.80, 0.60), vec2(-0.60, 0.80));

// Two plain octaves for the mass, then billowed octaves for the lobes. `detail`
// in 0..1 fades the billowed octaves, which is how the horizon band avoids
// aliasing under the shell projection's compression. Rotated between octaves
// so the lattice does not stack its features on the world axes -- the same
// banding a blind pass called "the loudest procedural signature" when it
// appeared in the ground cover.
float fbm_cumulus(vec2 p, float detail) {
	float v = 0.0;
	float a = 0.5;
	float norm = 0.0;
	for (int i = 0; i < 2; i++) {
		v += a * value_noise(p);
		norm += a;
		p = ROT * p * 2.1;
		a *= 0.55;
	}
	for (int i = 0; i < 3; i++) {
		float b = 1.0 - abs(2.0 * value_noise(p) - 1.0);
		v += a * b * detail;
		norm += a * detail;
		p = ROT * p * 2.1;
		a *= 0.55;
	}
	return v / max(norm, 1e-4);
}

// Cheap three-octave field for the sunward light sample: it only needs the
// gradient of the mass, not the lobes.
float fbm_light(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 3; i++) {
		v += a * value_noise(p);
		p = ROT * p * 2.1;
		a *= 0.55;
	}
	return v / 0.8025;
}

float fbm_cirrus(vec2 p) {
	float v = 0.5 * value_noise(p);
	p = ROT * p * 2.3;
	v += 0.5 * value_noise(p);
	return v;
}

void sky() {
	vec3 dir = normalize(EYEDIR);
	vec3 sun_dir = normalize(LIGHT0_DIRECTION);
	// See the `time_wrap` uniform's comment: raw TIME grows without bound over a
	// long-running render and degrades the fract()/floor() noise math below, so
	// every drift term uses this wrapped copy instead of TIME directly.
	float t_wrapped = mod(TIME, time_wrap);

	// The gradient, same shape ProceduralSkyMaterial produces so a coverage of
	// zero lands on the sky this replaces rather than on a different one.
	float up = dir.y;
	vec3 base = up >= 0.0
			? mix(horizon_colour, top_colour, pow(clamp(up, 0.0, 1.0), 0.45))
			: mix(ground_horizon_colour, ground_bottom_colour, pow(clamp(-up, 0.0, 1.0), 0.5));
	vec3 colour = base;

	if (up > 0.002) {
		// Shell projection: a deck at `cloud_altitude` above a flat observer.
		// Clouds overhead project large; toward the horizon `t` grows and the
		// same noise compresses, which is the perspective a plane never had.
		float t = cloud_altitude / max(up, 0.035);
		float horizon_fade = smoothstep(0.0, 0.10, up);
		float detail = smoothstep(0.04, 0.30, up);

		// Cirrus first: it sits above the cumulus, so cumulus paints over it.
		if (high_opacity > 0.0) {
			vec2 plane2 = dir.xz * (t * 2.6) * high_scale * vec2(0.35, 1.0) + wind * 1.8 * t_wrapped;
			float n2 = fbm_cirrus(plane2);
			float high = smoothstep(1.0 - high_coverage, 1.0 - high_coverage + 0.25, n2)
					* high_opacity * horizon_fade;
			vec3 cirrus = mix(cloud_shade, cloud_lit, 0.7);
			colour = mix(colour, cirrus, high);
		}

		vec2 plane = dir.xz * t * scale + wind * t_wrapped;
		float n = fbm_cumulus(plane, detail);
		// A second, slower sample displaces the first, which is what turns a
		// noise field into something with cauliflower edges instead of blobs.
		// Smaller than it was: 0.5 was most of the smear.
		n = fbm_cumulus(plane + vec2(n * 0.35, n * 0.25), detail);

		// Density with a defined edge. `thickness` is how deep into the cloud
		// this pixel is, for the base colour.
		float t0 = 1.0 - coverage;
		float soft = edge_softness > 0.0 ? edge_softness : (1.0 / sharpness);
		float mass = smoothstep(t0, t0 + soft, n);
		float density = pow(mass, 1.4) * horizon_fade;
		float thickness = clamp((n - t0) / max(1.0 - t0, 1e-3), 0.0, 1.0);

		// Light. `toward_sun` is the field a short step sunward: where it
		// drops, that edge is facing the sun and is bright; where it holds, we
		// are looking at the shaded body. A cheap stand-in for a light march
		// and the difference between clouds with form and flat white paper.
		vec2 sun_step = normalize(sun_dir.xz + vec2(0.0001)) * 0.06 * scale;
		float toward_sun = fbm_light(plane + sun_step);
		float here = fbm_light(plane);
		float lit_face = clamp((here - toward_sun) * lit_contrast + 0.5, 0.0, 1.0);
		vec3 shade = mix(cloud_shade, top_colour, 0.2);
		vec3 cloud = mix(shade, cloud_lit, lit_face);
		// The underside: thick, away from the sun, and lower on the dome.
		float under = smoothstep(0.45, 1.0, thickness) * (1.0 - lit_face) * (1.0 - smoothstep(0.3, 0.9, up));
		cloud = mix(cloud, cloud_base, under * 0.8);

		// Rim: the sun burning through a thin edge.
		float rim = pow(clamp(dot(dir, sun_dir), 0.0, 1.0), 8.0);
		cloud += sun_colour * rim * sun_gain * (1.0 - density) * density * 2.0;

		colour = mix(colour, cloud, clamp(density, 0.0, 1.0));
	}

	// Horizon haze band: `haze_colour` defaults to `horizon_colour`'s own
	// default (see that uniform's declaration) so an old preset that never
	// sets it lands on the same seam-matching behaviour as before -- but a
	// preset that DOES set `horizon_haze_colour` can bias the haze band
	// slightly bluer than the horizon it sits on, which is closer to how real
	// haze reads than repeating the horizon's own (often warm) tint.
	float haze = 1.0 - smoothstep(0.0, max(haze_height, 1e-3), abs(up));
	colour = mix(colour, haze_colour, haze * haze_strength);

	// The sun disc, which the gradient sky never had at all.
	//
	// T1-HALL-4, JUDGE-6 defect 11: at night this body "is a soft blurry ellipse
	// with no disc edge -- it reads as a LENS BLOOM rather than an object", and
	// the fix asked for is "replace the moon bloom with a disc". `disc_edge` is
	// the falloff fraction as a uniform, so a time of day can ask for a crisp
	// body (night, where a moon needs a rim) or a soft one (golden hour, where
	// the sun is meant to bloom).
	float sun_dot = dot(dir, sun_dir);
	float disc = smoothstep(1.0 - sun_size, 1.0 - sun_size * disc_edge, sun_dot);
	float glow = pow(clamp(sun_dot, 0.0, 1.0), sun_glow_falloff) * sun_glow;
	colour += sun_colour * (disc + glow) * LIGHT0_ENERGY;

	COLOR = colour * sky_energy;
}
