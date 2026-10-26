shader_type spatial;
// Ashfoot storm finish r25: the shelter window's storm pane. It tints the
// real exterior seen through the kit glass toward the storm purple, runs rain
// rivulets down the glass (more in the heavier phases) and lifts with the
// surge's own flash level in Break. No flashing of its own: `flash` is the
// surge's existing (reduced-motion aware) flash.
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec4 tint : source_color = vec4(0.36, 0.31, 0.53, 1.0);
uniform float tint_alpha = 0.5;
uniform float rain = 0.3;
uniform float flash = 0.0;
uniform vec4 flash_colour : source_color = vec4(0.86, 0.84, 1.0, 1.0);
uniform float rain_speed = 0.35;

float hash(float n) { return fract(sin(n) * 43758.5453); }

void fragment() {
	// Rivulets: thin columns at random x, each a few short drops sliding down.
	float lines = 0.0;
	for (int k = 0; k < 3; k++) {
		float columns = 18.0 + float(k) * 11.0;
		float id = floor(UV.x * columns);
		float seed = hash(id * 7.13 + float(k) * 19.7);
		if (seed < rain) {
			float x = fract(UV.x * columns) - (0.3 + 0.4 * hash(id * 3.1 + float(k)));
			float y = fract(UV.y * (1.5 + seed) - TIME * rain_speed * (0.6 + seed));
			lines += smoothstep(0.08, 0.0, abs(x)) * smoothstep(0.0, 0.25, y) * smoothstep(1.0, 0.55, y);
		}
	}
	vec3 colour = mix(tint.rgb, vec3(0.78, 0.8, 0.9), clamp(lines, 0.0, 1.0) * 0.6);
	colour = mix(colour, flash_colour.rgb, clamp(flash, 0.0, 1.0) * 0.7);
	ALBEDO = colour;
	ALPHA = clamp(tint_alpha + lines * 0.25 * rain + flash * 0.3, 0.0, 0.92);
}
