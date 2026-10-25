shader_type spatial;
render_mode blend_add, unshaded, depth_draw_never, cull_back, shadows_disabled, fog_disabled;

// Natural glow for Meshy hero props whose crystal or lightning veins are
// painted into one albedo atlas (Stormwood heartstone crystal, Stormheart
// root-wall veins). Added as a next pass: only texels that are clearly blue
// and bright light up, so bark, stone and moss stay unlit (owner glow rule:
// glow only where natural to the element, never seams on fur or hide).
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap;
uniform vec3 glow_colour : source_color = vec3(0.45, 0.75, 1.0);
uniform float glow_energy = 1.2;
uniform float blue_margin = 0.12;
uniform float min_value = 0.35;

void fragment() {
	vec3 c = texture(albedo_tex, UV).rgb;
	float blueness = c.b - max(c.r, c.g);
	float mask = smoothstep(blue_margin, blue_margin + 0.12, blueness) * smoothstep(min_value, min_value + 0.2, c.b);
	ALBEDO = glow_colour * glow_energy * mask;
}
