shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

uniform vec4 energy_colour : source_color = vec4(0.31, 0.76, 0.8, 1.0);
uniform float intensity = 0.35;
uniform float centre_opacity = 0.18;
uniform float edge_opacity = 0.65;
uniform float seal_presence = 1.0;
uniform float seal_ready = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
float noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(cell), hash(cell + vec2(1.0, 0.0)), f.x),
		mix(hash(cell + vec2(0.0, 1.0)), hash(cell + vec2(1.0)), f.x), f.y);
}
void fragment() {
	float edge = pow(abs(UV.x * 2.0 - 1.0), 9.0);
	float drift = noise(vec2(UV.x * 5.0 + sin(UV.y * 6.0 + TIME * 0.18) * 0.3,
		UV.y * 4.0 - TIME * 0.12));
	float threads = pow(0.5 + 0.5 * sin(UV.x * 60.0 + drift * 7.0 + TIME * 0.25), 12.0);
	float foot = smoothstep(0.0, 0.045, UV.y);
	// A discrete diamond seal remains readable when the veil's subtle colour
	// change is too small. The ready state adds a warm outer halo; open clears it.
	vec2 mark = (UV - vec2(0.5, 0.62)) * vec2(0.8, 1.0);
	float diamond = abs(mark.x) + abs(mark.y);
	float rune = 1.0 - smoothstep(0.006, 0.012, abs(diamond - 0.078));
	float bar = (1.0 - smoothstep(0.005, 0.010, abs(mark.x)))
		* (1.0 - smoothstep(0.047, 0.056, abs(mark.y)));
	float halo = (1.0 - smoothstep(0.004, 0.010, abs(length(mark) - 0.116))) * seal_ready;
	float sign_alpha = max(max(rune, bar), halo) * seal_presence;
	vec3 sign_colour = mix(vec3(0.45, 0.57, 0.59), vec3(0.95, 0.73, 0.33), seal_ready);
	ALBEDO = energy_colour.rgb * (0.6 + drift * 0.25);
	EMISSION = energy_colour.rgb * intensity * (0.25 + edge * 0.8 + threads * 0.18);
	ALPHA = (centre_opacity * (0.65 + drift * 0.25 + threads * 0.1)
		+ edge * edge_opacity) * foot;
	ALBEDO = mix(ALBEDO, sign_colour, sign_alpha);
	EMISSION += sign_colour * sign_alpha * (0.25 + seal_ready * 0.75);
	ALPHA = max(ALPHA, sign_alpha * 0.95);
}
