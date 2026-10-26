shader_type spatial;
render_mode blend_add, unshaded, depth_draw_never, cull_back, shadows_disabled, fog_disabled;

// Natural flame light for Meshy lanterns whose lit glass panes are painted
// into one albedo atlas (Stormwood lantern post). Added as a next pass: only
// texels that are clearly warm and bright (the candle-lit panes) light up, so
// timber, copper, patina, stone and moss stay unlit (owner glow rule: glow
// only where natural to the element).
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap;
uniform vec3 glow_colour : source_color = vec3(1.0, 0.78, 0.45);
uniform float glow_energy = 1.4;
uniform float warm_margin = 0.12;
uniform float min_value = 0.68;

void fragment() {
	vec3 c = texture(albedo_tex, UV).rgb;
	float warmth = c.r - c.b;
	float mask = smoothstep(warm_margin, warm_margin + 0.12, warmth) * smoothstep(min_value, min_value + 0.15, max(c.r, c.g));
	ALBEDO = glow_colour * glow_energy * mask;
}
