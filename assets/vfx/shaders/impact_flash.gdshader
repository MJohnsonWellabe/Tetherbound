shader_type spatial;
// Camera-facing additive contact flash on a QuadMesh: a hot core with short
// irregular streaks, alive for a few frames at contact (or launch). Procedural,
// depth-tested, Compatibility-safe; never covers the target for long.
render_mode blend_add, unshaded, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec4 core_colour : source_color = vec4(1.0, 0.97, 0.88, 1.0);
uniform vec4 edge_colour : source_color = vec4(1.0, 0.62, 0.22, 1.0);
uniform float opacity = 1.0;
// 0 at birth, 1 at the end of the flash.
uniform float age = 0.0;
uniform int streaks = 7;
uniform float streak_strength = 0.55;
uniform float seed = 0.0;

float hash(float x) {
	return fract(sin(x * 91.3 + seed * 13.7) * 43758.5453);
}

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
		vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
		vec4(0.0, 0.0, 0.0, 1.0));
}

void fragment() {
	vec2 c = UV * 2.0 - 1.0;
	float r = length(c);
	float a = atan(c.y, c.x);
	float sector = a / 6.2831853 * float(streaks);
	float id = floor(sector);
	float local = abs(fract(sector) - 0.5);
	float reach = 0.55 + 0.45 * hash(id);
	float streak = (1.0 - smoothstep(0.02, 0.12, local)) * (1.0 - smoothstep(reach * 0.4, reach, r));
	float core = exp(-r * r * 9.0);
	float halo = exp(-r * r * 2.6) * 0.45;
	float life = pow(1.0 - clamp(age, 0.0, 1.0), 1.6);
	vec3 colour = mix(edge_colour.rgb, core_colour.rgb, clamp(core * 1.4, 0.0, 1.0));
	float intensity = (core + halo + streak * streak_strength) * life * opacity;
	ALBEDO = colour * intensity;
	ALPHA = clamp(intensity, 0.0, 1.0);
}
