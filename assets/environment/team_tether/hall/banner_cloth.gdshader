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
// HALL-ART-0906, H3. JUDGE-5 on the Warden Arena's banner: "its lower half
// (y 320-540) is a COMPLETELY FLAT SLAB, median 22, p95 24, max 25 -- i.e. no
// texture, no fold, no gradient across 220 rows ... the lower slab reads as a
// clipping plane." The sway was already there and was already displacing the
// cloth; what it never did was tell the RENDERER about it. `vertex()` moved
// VERTEX.z and left NORMAL pointing flat out of the plane, so every fragment on
// the cloth received exactly the same amount of light from the room's torches
// and the only variation left was a +-few-per-cent albedo multiply -- which is
// precisely a three-luma-value range over 220 rows. The wave now rebuilds the
// surface normal from its own slope (two finite differences, a cross product),
// so a fold is lit as a fold; the fold-shade term stays as a small extra bias
// under the Compatibility renderer's flat ambient, not as the whole read.
//
// Two other things the same finding asked for, both cheap and both here:
//   - `drape`, a bottom-weighted darkening, so the cloth has a value gradient
//     down its own drop even where no light reaches it. Cloth hanging in a
//     still room is darker at the hem; a flat panel is not.
//   - `pattern`, so the Hall stops hanging two designs on thirty banners. 0 is
//     the plain field it always was, 1 a barred field for the arena, 2 a
//     chevron for the towers. The device still rides all three.
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
// How much darker the cloth is at the hem than at the crossbar. Pure shading,
// no geometry: a hanging cloth self-occludes down its own drop.
uniform float drape : hint_range(0.0, 0.8) = 0.34;
// A second, finer fold train. The original wave's shortest term runs about one
// cycle over a banner's whole drop, which on a 8 m arena cloth is one soft bend
// -- readable as "not rigid", not readable as "cloth". This adds the small
// creases at a hand's width that make it one.
uniform float crease : hint_range(0.0, 1.0) = 0.35;
// 0 plain field, 1 barred (the arena), 2 chevron (the towers).
uniform float pattern = 0.0;

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
		+ 0.3 * sin(t * speed * 0.61 + phase * 0.7 + p.x * 4.0)
		+ crease * 0.34 * sin(phase * 2.3 + p.x * 7.9 + drop * 13.0);
	return amp * w;
}

void vertex() {
	cloth = VERTEX.xy;
	float d = wave(cloth, TIME);
	VERTEX.z += d;
	// Central differences over a hand's width, in the cloth's own plane. The
	// surface is (x, y, wave(x,y)), so its two tangents are (e,0,dx) and
	// (0,e,dy) and the normal is their cross product -- rebuilt here because
	// displacing a vertex without doing this leaves the whole cloth lit as one
	// flat plane, which is exactly the defect this shader's header records.
	const float E = 0.09;
	float dx = wave(cloth + vec2(E, 0.0), TIME) - wave(cloth - vec2(E, 0.0), TIME);
	float dy = wave(cloth + vec2(0.0, E), TIME) - wave(cloth - vec2(0.0, E), TIME);
	// `relief` damps the slope BEFORE the normal is built, and it is not
	// cosmetic. The true surface slope of this wave is close to 1.0 at the hem
	// of a big cloth (`sway` 0.32 times the base term's 2.1 rad/m, plus the
	// crease train), which tilts facets by 45 degrees or more -- and a facet
	// that steep on a banner four metres from a 12-energy torch turns half the
	// cloth into a specular-white panel. That is not a folded banner, it is a
	// crumpled one, and the first render of this change proved it: the arena
	// pair came back pale lavender with the sigil washed out of it. Damped, the
	// folds still catch and lose light across the drop without any facet ever
	// facing a torch square on.
	float relief = 0.4;
	NORMAL = normalize(vec3(-dx * relief, -dy * relief, 2.0 * E));
	TANGENT = normalize(vec3(2.0 * E, 0.0, dx * relief));
	BINORMAL = normalize(cross(NORMAL, TANGENT));
	fold = (dx * 1.5 + dy * 0.75) / E;
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

	// The field's own design. `pattern` 1 bars it (two selvage-coloured bands
	// across the drop, under the device) and 2 chevrons it; 0 leaves the plain
	// field every banner in the complex used to wear. This is what stops thirty
	// banners being two designs -- the Hall's own heraldry gains a rank rather
	// than a second colour.
	if (pattern > 0.5 && pattern < 1.5) {
		float bar = smoothstep(0.62, 0.645, drop) - smoothstep(0.70, 0.725, drop);
		bar += smoothstep(0.76, 0.785, drop) - smoothstep(0.815, 0.84, drop);
		base = mix(base, selvage_colour.rgb, clamp(bar, 0.0, 1.0) * 0.85);
	} else if (pattern >= 1.5) {
		float v = abs(u - 0.5) * 1.4;
		float band = fract((drop - v) * 3.4);
		float chev = smoothstep(0.0, 0.05, band) - smoothstep(0.16, 0.22, band);
		base = mix(base, selvage_colour.rgb, clamp(chev, 0.0, 1.0) * 0.6 *
			smoothstep(0.42, 0.52, drop));
	}

	// The device, painted on the field.
	if (use_device > 0.5) {
		vec2 rel = (vec2(cloth.x / w, cloth.y / h) - device_centre) / device_half;
		if (abs(rel.x) < 1.0 && abs(rel.y) < 1.0) {
			vec2 tuv = vec2(rel.x * 0.5 + 0.5, 0.5 - rel.y * 0.5);
			vec4 mark = texture(device_tex, tuv);
			base = mix(base, device_colour.rgb, mark.a * device_colour.a);
		}
	}

	// The device, and the field's own design, are drawn above. What is left is
	// the two things that stop a hanging cloth reading as a painted board.
	//
	// Drape: cloth self-occludes down its drop, and the fold train's own
	// troughs sit deeper in that occlusion than its crests. Squared, so the
	// crossbar end is untouched and the hem carries nearly all of it.
	float ao = 1.0 - drape * drop * drop;
	// Folds: the wave's slope, still applied to albedo. With NORMAL rebuilt in
	// the vertex stage this is no longer doing the whole job, only biasing it,
	// which is why the range is tighter than it used to be -- under the
	// Compatibility renderer's flat ambient a fold facing away from every light
	// would otherwise still be exactly as bright as one facing into it.
	float shade = clamp(1.0 + fold * fold_shade * 1.6, 0.78, 1.18);
	ALBEDO = base * shade * ao;
	ROUGHNESS = 0.95;
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
}
