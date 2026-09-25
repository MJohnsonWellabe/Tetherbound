shader_type spatial;
// Closed-gate tide race (Tidewake, WORLD §6.1): broken white water streaming
// outward over churned sea-teal, used only by scripts/world/water_gate_seal_view.gd.
// Vertex colour alpha carries each mesh's authored fade; UV.x runs along the
// ring, UV.y outward (flat race) or up the face (breakers).
render_mode blend_mix, depth_draw_opaque, cull_disabled, specular_schlick_ggx;

uniform sampler2D foam_noise : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D detail_noise : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec4 foam_colour : source_color = vec4(0.94, 0.97, 1.0, 1.0);
uniform vec4 churn_colour : source_color = vec4(0.12, 0.36, 0.38, 1.0);
uniform vec4 face_colour : source_color = vec4(0.18, 0.45, 0.46, 1.0);
uniform float flow_tiles_per_s = 0.35;
uniform float crest_cycle_speed = 1.6;
uniform float crest_spacing_tiles = 3.0;
uniform float foam_cover = 0.52;
uniform float foam_softness = 0.12;
uniform float opacity = 0.92;
// 0 = flat race ring, 1 = standing breaker.
uniform float breaker = 0.0;

void fragment() {
	vec2 flow = vec2(0.0, -TIME * flow_tiles_per_s);
	// Two octaves moving at different speeds read as tumbling, not sliding.
	float coarse = texture(foam_noise, UV * vec2(1.0, 1.0) + flow).r;
	float fine = texture(detail_noise, UV * vec2(2.7, 3.1) + flow * 1.7 + vec2(0.13, 0.0)).r;
	float cells = coarse * 0.65 + fine * 0.35;
	// Crest pulses travel around the ring: brighter bands of breaking foam.
	float pulse = 0.5 + 0.5 * sin(UV.x * 6.2831853 / crest_spacing_tiles - TIME * crest_cycle_speed);
	float cover = foam_cover - 0.14 * pulse;
	// Breakers: foam gathers toward the lip (UV.y up the face).
	cover -= breaker * clamp(UV.y * 1.4, 0.0, 0.35);
	float foam = smoothstep(cover - foam_softness, cover + foam_softness, cells);
	vec3 base = mix(churn_colour.rgb, face_colour.rgb, breaker);
	ALBEDO = mix(base, foam_colour.rgb, foam);
	ROUGHNESS = mix(0.18, 0.75, foam);
	SPECULAR = 0.5;
	// Churned water under the foam stays partly see-through; foam is dense.
	float body = mix(0.55, 1.0, foam);
	ALPHA = clamp(COLOR.a * opacity * body, 0.0, 1.0);
}
