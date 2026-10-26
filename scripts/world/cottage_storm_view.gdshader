shader_type spatial;
// Ashfoot r36: the storm seen through the shelter window. A card a few metres
// outside the east window, facing the room (back faces culled, so it is never
// drawn from outside): a storm sky over a dark treeline, drifting cloud, rain
// and the surge's own flash. Phase values come from cottage_interior.gd; no
// flashing of its own beyond the surge's (reduced-motion aware) flash level.
render_mode unshaded, cull_back, shadows_disabled, fog_disabled;

uniform vec4 sky_top : source_color = vec4(0.16, 0.13, 0.26, 1.0);
uniform vec4 sky_low : source_color = vec4(0.42, 0.38, 0.55, 1.0);
uniform vec4 tree_colour : source_color = vec4(0.05, 0.07, 0.07, 1.0);
uniform float cloud = 0.6;
uniform float rain = 0.4;
uniform float flash = 0.0;
uniform vec4 flash_colour : source_color = vec4(0.86, 0.84, 1.0, 1.0);
uniform float treeline = 0.32;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float total = 0.0;
	float amp = 0.5;
	for (int k = 0; k < 4; k++) {
		total += noise(p) * amp;
		p *= 2.03;
		amp *= 0.5;
	}
	return total;
}

void fragment() {
	float height = 1.0 - UV.y;
	vec3 sky = mix(sky_low.rgb, sky_top.rgb, smoothstep(0.2, 1.0, height));
	// Heavy cloud banks drifting slowly.
	float c = fbm(vec2(UV.x * 3.0 + TIME * 0.015, height * 2.2));
	sky = mix(sky, sky_top.rgb * 0.55, smoothstep(0.45, 0.8, c) * cloud);
	sky = mix(sky, sky_low.rgb * 1.15, smoothstep(0.62, 0.9, fbm(vec2(UV.x * 5.0 - TIME * 0.01, height * 4.0))) * cloud * 0.5);
	// The surge's flash lights the cloud from inside.
	sky = mix(sky, flash_colour.rgb, clamp(flash, 0.0, 1.0) * (0.35 + 0.5 * c));
	// A dark, ragged conifer treeline.
	float ridge = treeline + 0.08 * fbm(vec2(UV.x * 6.0, 0.0)) + 0.06 * abs(sin(UV.x * 61.0)) * noise(vec2(UV.x * 40.0, 1.0));
	vec3 colour = height < ridge ? tree_colour.rgb + flash_colour.rgb * flash * 0.08 : sky;
	// Rain: fine slanted streaks.
	vec2 r = vec2(UV.x * 90.0 + height * 9.0, height * 6.0 + TIME * 3.0);
	float streak = step(0.985 - rain * 0.03, hash(vec2(floor(r.x), floor(r.y))));
	colour = mix(colour, vec3(0.75, 0.78, 0.88), streak * rain * 0.35);
	ALBEDO = colour;
}
