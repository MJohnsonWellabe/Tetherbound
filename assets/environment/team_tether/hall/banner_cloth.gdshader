// VP8 (visual parity, Meadows Hall). Team Tether's war banners as CLOTH.
//
// Every banner at the Hall used to be three boxes (a field and two tails), two
// selvage strips and a sigil quad: six draw calls of rigid, flat rectangles.
// JUDGE-6 defect 10: "a perfectly rigid rectangle with a rectangular notch cut
// out of the bottom -- no cloth curve, no ripple, no thickness, no wind ... it
// reads as a laminated sign." The Visual Bible asks for "convincing cloth
// banners"; the owner's own pack asks for "real 3D cloth folds".
//
// This is one subdivided plane per banner carrying the whole read:
//   - the field, the two swallow tails and the V notch between them (a `discard`
//     shaped from the cloth's own local position, so the silhouette is cut
//     rather than assembled);
//   - the selvage borders and a darker hem, in the fragment rather than as
//     extra geometry;
//   - the faction device, sampled into a rectangle of the field from the same
//     image every other Tether mark in the game is drawn from
//     (`tether_sigil.gd::texture()`), so the mark rides the folds;
//   - the sway: a vertex displacement out of the cloth plane that is zero at the
//     crossbar and grows toward the hem, two summed sines in TIME so no two
//     banners are in step (each carries its own `phase`), with the same
//     function's slope used to shade the folds so the cloth reads as folded even
//     under the Compatibility renderer's flat ambient.
//
// `tails` = 2 is the ordinary swallowtail; 1 is the relic banner (§6.2) with one
// tail torn away and a ragged hem. Local frame: the mesh is a QuadMesh in its
// own XY plane, +X across the cloth, +Y up (the crossbar is at +size.y/2),
// normal +Z; the caller rotates the instance so +Z is the banner's outward
// side. Everything here is in that frame.

shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_disabled;

// Default kept in sync with stronghold.gd's BANNER_COLOUR (#66362c); every
// real caller sets this uniform explicitly (`_banner_cloth_material`), so the
// default only matters if a future caller forgets to.
uniform vec4 colour : source_color = vec4(0.4, 0.212, 0.173, 1.0);
uniform vec4 selvage_colour : source_color = vec4(0.25, 0.09, 0.08, 1.0);
uniform vec4 device_colour : source_color = vec4(0.91, 0.87, 0.77, 1.0);
uniform sampler2D device_tex : source_color, filter_linear_mipmap;
uniform float use_device : hint_range(0.0, 1.0) = 1.0;
// The device's rectangle inside the field: centre (fraction of width/height
// from the cloth centre, +y up) and half-size (fractions of width/height).
uniform vec2 device_centre = vec2(0.0, 0.14);
uniform vec2 device_half = vec2(0.31, 0.23);
uniform vec2 size = vec2(1.35, 2.0);
uniform float tails = 2.0;
uniform float notch_depth : hint_range(0.0, 0.6) = 0.26;
uniform float selvage : hint_range(0.0, 0.3) = 0.075;
uniform float sway = 0.14;
uniform float speed = 1.2;
uniform float phase = 0.0;
uniform float fold_shade : hint_range(0.0, 1.0) = 0.22;

varying vec2 cloth;       // local x (-w/2..w/2), local y (+h/2 at the bar)
varying float fold;

float hash1(float n) {
	return fract(sin(n * 127.1 + 311.7) * 43758.5453);
}

// Out-of-plane displacement at a point on the cloth, and (via a finite
// difference in the fragment) its slope for the fold shading.
float wave(vec2 p, float t) {
	float drop = clamp((size.y * 0.5 - p.y) / size.y, 0.0, 1.0);   // 0 at the bar, 1 at the hem
	float amp = pow(drop, 1.6) * sway;
	float w = sin(t * speed + phase + p.x * 2.1 + drop * 3.0)
		+ 0.55 * sin(t * speed * 1.73 + phase * 1.3 + drop * 6.5 - p.x * 1.2)
		+ 0.3 * sin(t * speed * 0.61 + phase * 0.7 + p.x * 4.0);
	return amp * w;
}

void vertex() {
	cloth = VERTEX.xy;
	float d = wave(cloth, TIME);
	VERTEX.z += d;
	float dx = wave(cloth + vec2(0.08, 0.0), TIME) - d;
	float dy = wave(cloth + vec2(0.0, -0.08), TIME) - d;
	fold = (dx * 3.0 + dy * 1.5);
}

void fragment() {
	float w = size.x;
	float h = size.y;
	float u = cloth.x / w + 0.5;                // 0 left .. 1 right
	float drop = clamp((h * 0.5 - cloth.y) / h, 0.0, 1.0);   // 0 bar .. 1 hem

	// The swallowtail: a V cut up from the hem's centre.
	float into_notch = (drop - (1.0 - notch_depth)) / max(notch_depth, 0.001);
	if (into_notch > 0.0) {
		float cut_half = 0.28 * into_notch;         // as a fraction of the width
		if (abs(u - 0.5) < cut_half) {
			discard;
		}
		if (tails < 1.5 && u > 0.5) {
			// The torn banner: one tail gone, the other ragged.
			discard;
		}
	}
	if (tails < 1.5) {
		float rag = 0.86 + 0.09 * hash1(floor(u * 14.0));
		if (drop > rag && u > 0.5) {
			discard;
		}
		if (drop > 0.94 + 0.05 * hash1(floor(u * 9.0) + 3.0)) {
			discard;
		}
	}

	vec3 base = colour.rgb;
	// Selvage borders down both edges and a hem band.
	float edge = min(u, 1.0 - u);
	float border = 1.0 - smoothstep(selvage * 0.7, selvage, edge);
	base = mix(base, selvage_colour.rgb, border);
	base = mix(base, selvage_colour.rgb, smoothstep(0.90, 0.985, drop) * 0.7);
	// Weave: faint warp lines and per-thread value noise so the field is not
	// one flat fill.
	base *= 0.985 + 0.015 * sin(cloth.x * 31.0 + cloth.y * 3.0) + 0.03 * (hash1(floor(cloth.x * 40.0) + floor(cloth.y * 40.0) * 7.0) - 0.5);

	// The device, painted on the field.
	if (use_device > 0.5) {
		vec2 rel = (vec2(cloth.x / w, cloth.y / h) - device_centre) / device_half;
		if (abs(rel.x) < 1.0 && abs(rel.y) < 1.0) {
			vec2 tuv = vec2(rel.x * 0.5 + 0.5, 0.5 - rel.y * 0.5);
			vec4 mark = texture(device_tex, tuv);
			base = mix(base, device_colour.rgb, mark.a * device_colour.a);
		}
	}

	// Folds: the wave's slope shades one side of each ripple.
	float shade = clamp(1.0 + fold * fold_shade * 6.0, 0.7, 1.15);
	ALBEDO = base * shade;
	ROUGHNESS = 0.95;
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
}
